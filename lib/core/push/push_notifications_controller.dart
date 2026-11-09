import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/home/home_controller.dart';
import '../../features/notifications/data/models/notification_model.dart';
import '../../features/notifications/notification_navigation.dart';
import '../../features/notifications/presentation/notifications_controller.dart';
import '../router/app_router.dart';
import 'push_messaging.dart';
import 'push_payload.dart';
import 'push_tokens_repository.dart';

/// Where a tapped push is opened. Kept apart from the controller so the push
/// flow can be tested without a router.
abstract class PushOpener {
  /// Fires when [isReady] may have changed.
  Listenable get readiness;

  /// True once the student is past splash, sign-in and the terms gate.
  bool get isReady;

  /// Opens the page for [notification], or the notifications list.
  void open(NotificationModel? notification);
}

class RouterPushOpener implements PushOpener {
  RouterPushOpener(this._router);

  final GoRouter _router;

  static const _notReady = [
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.verifyEmail,
    AppRoutes.forgotPassword,
    '/password-reset',
    AppRoutes.maintenance,
    AppRoutes.termsAcceptance,
  ];

  @override
  Listenable get readiness => _router.routerDelegate;

  @override
  bool get isReady {
    final configuration = _router.routerDelegate.currentConfiguration;
    if (configuration.isEmpty || rootNavigatorKey.currentContext == null) {
      return false;
    }
    final location = configuration.uri.path;
    return !_notReady.any(location.startsWith);
  }

  @override
  void open(NotificationModel? notification) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    if (notification == null) {
      _router.push(AppRoutes.notifications);
      return;
    }
    NotificationNavigation.open(context, notification);
  }
}

/// Push notifications on top of the existing in-app notifications.
///
///  - Registers this install's FCM token for the signed-in session, again
///    whenever FCM rotates it, and drops it when the session ends, so a
///    phone never keeps getting a previous account's pushes.
///  - Opens the linked page when a push is tapped (from background or from
///    closed), once the student is signed in, and only for the account the
///    push was sent to.
///  - Refreshes the notifications list and the home badge when a push
///    arrives while the app is open.
class PushNotificationsController {
  PushNotificationsController({
    required Ref ref,
    required Future<PushMessaging?> Function() resolveMessaging,
    required PushTokensRepository repository,
    required PushOpener opener,
    Future<String?> Function()? appVersion,
  }) : _ref = ref,
       _resolveMessaging = resolveMessaging,
       _repository = repository,
       _opener = opener,
       _appVersion = appVersion ?? _packageVersion;

  final Ref _ref;
  final Future<PushMessaging?> Function() _resolveMessaging;
  final PushTokensRepository _repository;
  final PushOpener _opener;
  final Future<String?> Function() _appVersion;

  final _subscriptions = <StreamSubscription<Object?>>[];
  PushMessaging? _messaging;
  bool _started = false;
  bool _disposed = false;

  String? _registeredToken;
  int? _registeredUserId;
  PushMessage? _pending;

  @visibleForTesting
  String? get registeredToken => _registeredToken;

  @visibleForTesting
  PushMessage? get pendingOpen => _pending;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final messaging = await _resolveMessaging();
    if (messaging == null || _disposed) return;
    _messaging = messaging;

    _subscriptions
      ..add(messaging.onTokenRefresh.listen(_onTokenRefresh))
      ..add(messaging.onForegroundMessage.listen(_onForeground))
      ..add(messaging.onMessageOpenedApp.listen(_onOpened));
    _opener.readiness.addListener(_tryOpenPending);

    final auth = _ref.read(authControllerProvider);
    if (auth.status == AuthStatus.authenticated && auth.user != null) {
      unawaited(_register(auth.user!.id));
    }

    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) _onOpened(initial);
    } catch (error) {
      _log('initial message', error);
    }
  }

  void onAuthChanged(AuthState? previous, AuthState next) {
    final signedIn =
        next.status == AuthStatus.authenticated && next.user != null;
    final startedSession =
        signedIn &&
        (previous?.status != AuthStatus.authenticated ||
            previous?.user?.id != next.user!.id);
    final signedOut =
        next.status == AuthStatus.unauthenticated &&
        previous?.status != AuthStatus.unauthenticated;

    if (startedSession) {
      unawaited(_register(next.user!.id));
      _tryOpenPending();
    } else if (signedOut) {
      unawaited(_unlink());
    }
  }

  int? get _currentUserId {
    final auth = _ref.read(authControllerProvider);
    return auth.status == AuthStatus.authenticated ? auth.user?.id : null;
  }

  Future<void> _register(int userId) async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      if (!await messaging.requestPermission()) return;
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _send(token, userId);
    } catch (error) {
      _log('register', error);
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    final userId = _currentUserId;
    if (userId == null || token.isEmpty) return;
    try {
      await _send(token, userId);
    } catch (error) {
      _log('token refresh', error);
    }
  }

  Future<void> _send(String token, int userId) async {
    if (_registeredToken == token && _registeredUserId == userId) return;
    // The student may have signed out while permission or the token was
    // being fetched.
    if (_currentUserId != userId || _disposed) return;

    await _repository.register(
      token: token,
      platform: _messaging!.platform,
      appVersion: await _appVersion(),
    );
    _registeredToken = token;
    _registeredUserId = userId;
  }

  /// The server already forgot the token with the session; deleting it here
  /// too means the next account on this phone gets a fresh one.
  Future<void> _unlink() async {
    _registeredToken = null;
    _registeredUserId = null;
    _pending = null;
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      await messaging.clearDelivered();
      await messaging.deleteToken();
    } catch (error) {
      _log('unlink', error);
    }
  }

  void _onForeground(PushMessage message) {
    final userId = _currentUserId;
    if (userId == null) return;
    final owner = message.ownerId;
    if (owner != null && owner != userId) return;

    unawaited(
      _messaging?.presentForeground(message).catchError((Object error) {
        _log('present', error);
      }),
    );
    _refreshInbox();
  }

  void _onOpened(PushMessage message) {
    _pending = message;
    _tryOpenPending();
  }

  void _tryOpenPending() {
    final message = _pending;
    if (message == null || _disposed) return;

    final auth = _ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated || auth.user == null) {
      // Opened once the student signs in, if it's the same account.
      return;
    }
    final owner = message.ownerId;
    if (owner != null && owner != auth.user!.id) {
      // Sent to another account that used this phone: never show it.
      _pending = null;
      return;
    }
    if (!_opener.isReady) return;

    _pending = null;
    // Let the current navigation settle before pushing on top of it; ask
    // for a frame so this doesn't wait on an idle screen.
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (_disposed) return;
      final notification = message.toNotification();
      _opener.open(notification);
      unawaited(_markRead(notification));
    });
    binding.ensureVisualUpdate();
  }

  Future<void> _markRead(NotificationModel? notification) async {
    if (notification == null || notification.id <= 0) {
      _refreshInbox();
      return;
    }
    try {
      await _ref
          .read(notificationsListControllerProvider.notifier)
          .markAsRead(notification.id);
    } catch (error) {
      _log('mark read', error);
    }
    _refreshInbox();
  }

  void _refreshInbox() {
    if (_disposed) return;
    unawaited(
      _ref
          .read(notificationsListControllerProvider.notifier)
          .load(refresh: true),
    );
    final home = _ref.read(homeControllerProvider);
    if (home.status == HomeLoadStatus.loaded) {
      unawaited(_ref.read(homeControllerProvider.notifier).load(refresh: true));
    }
  }

  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    if (_messaging != null) {
      _opener.readiness.removeListener(_tryOpenPending);
    }
  }

  static Future<String?> _packageVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return null;
    }
  }

  static void _log(String step, Object error) {
    if (kDebugMode) debugPrint('Push $step failed: $error');
  }
}

final pushOpenerProvider = Provider<PushOpener>((ref) {
  return RouterPushOpener(ref.watch(appRouterProvider));
});

final pushNotificationsControllerProvider =
    Provider<PushNotificationsController>((ref) {
      final controller = PushNotificationsController(
        ref: ref,
        resolveMessaging: FirebasePushMessaging.resolve,
        repository: ref.watch(pushTokensRepositoryProvider),
        opener: ref.watch(pushOpenerProvider),
      );
      ref.listen<AuthState>(authControllerProvider, controller.onAuthChanged);
      ref.onDispose(controller.dispose);
      unawaited(controller.start());
      return controller;
    });
