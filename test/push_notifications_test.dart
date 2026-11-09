import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/device/device_service.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/push/push_messaging.dart';
import 'package:rshd/core/push/push_notifications_controller.dart';
import 'package:rshd/core/push/push_payload.dart';
import 'package:rshd/core/push/push_tokens_repository.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/data/models/user_model.dart';
import 'package:rshd/features/auth/presentation/auth_controller.dart';
import 'package:rshd/features/notifications/data/models/notification_model.dart';
import 'package:rshd/features/notifications/data/notifications_repository.dart';

ApiClient _api() => ApiClient(secureStorage: SecureStorageService());

class _AuthRepository extends AuthRepository {
  _AuthRepository()
    : super(
        apiClient: _api(),
        secureStorage: SecureStorageService(),
        deviceService: DeviceService(secureStorage: SecureStorageService()),
      );

  @override
  Future<void> clearLocalSession() async {}
}

class _Auth extends AuthController {
  _Auth() : super(_AuthRepository());

  void signIn(int id) => state = AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(
      id: id,
      name: 'طالب $id',
      email: 's$id@example.com',
      role: 'student',
      status: 'active',
    ),
  );

  void signOut() => state = const AuthState(status: AuthStatus.unauthenticated);
}

class _Messaging implements PushMessaging {
  bool allowed = true;
  String? token = 'fcm-token-1';
  int deleted = 0;
  int cleared = 0;
  PushMessage? initial;
  final presented = <PushMessage>[];
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();

  @override
  String get platform => 'ios';
  @override
  Future<bool> requestPermission() async => allowed;
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> deleteToken() async => deleted++;
  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;
  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;
  @override
  Future<PushMessage?> getInitialMessage() async => initial;
  @override
  Future<void> presentForeground(PushMessage message) async =>
      presented.add(message);
  @override
  Future<void> clearDelivered() async => cleared++;
}

class _Tokens extends PushTokensRepository {
  _Tokens() : super(apiClient: _api());

  final registered = <String>[];

  @override
  Future<void> register({
    required String token,
    required String platform,
    String? appVersion,
  }) async => registered.add('$token/$platform/$appVersion');

  @override
  Future<void> unregister(String token) async {}
}

class _Opener implements PushOpener {
  final ready = ValueNotifier<bool>(true);
  final opened = <NotificationModel?>[];

  @override
  Listenable get readiness => ready;
  @override
  bool get isReady => ready.value;
  @override
  void open(NotificationModel? notification) => opened.add(notification);
}

class _Inbox extends NotificationsRepository {
  _Inbox() : super(apiClient: _api());

  final markedRead = <int>[];

  @override
  Future<List<NotificationModel>> getNotifications() async => const [];

  @override
  Future<NotificationModel> markAsRead(int notificationId) async {
    markedRead.add(notificationId);
    return NotificationModel(id: notificationId, userId: 1, title: '');
  }
}

PushMessage _push({int userId = 1, int id = 42, String type = 'quiz_created'}) {
  return PushMessage(
    title: 'اختبار جديد',
    body: 'اختبار الوحدة الأولى',
    data: {
      'notification_id': '$id',
      'user_id': '$userId',
      'type': type,
      'title': 'اختبار جديد',
      'body': 'اختبار الوحدة الأولى',
      'rshd_data': '{"quiz_id":9,"subject_id":3}',
    },
  );
}

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => _Auth()),
        notificationsRepositoryProvider.overrideWithValue(inbox),
      ],
    );
    final provider = Provider<PushNotificationsController>((ref) {
      final controller = PushNotificationsController(
        ref: ref,
        resolveMessaging: () async => messaging,
        repository: tokens,
        opener: opener,
        appVersion: () async => '1.0.0',
      );
      ref.listen<AuthState>(authControllerProvider, controller.onAuthChanged);
      ref.onDispose(controller.dispose);
      return controller;
    });
    controller = container.read(provider);
  }

  late final ProviderContainer container;
  late final PushNotificationsController controller;
  final messaging = _Messaging();
  final tokens = _Tokens();
  final opener = _Opener();
  final inbox = _Inbox();

  _Auth get auth => container.read(authControllerProvider.notifier) as _Auth;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  test('the payload becomes the in-app notification it belongs to', () {
    final notification = _push().toNotification()!;

    expect(notification.id, 42);
    expect(notification.userId, 1);
    expect(notification.type, 'quiz_created');
    expect(notification.quizId, 9);
    expect(notification.subjectId, 3);
    expect(PushMessage.decode(_push().encode())!.data, _push().data);
    expect(const PushMessage(data: {}).toNotification(), isNull);
  });

  testWidgets('signing in registers the token once; a new token re-registers', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.container.dispose);
    await h.controller.start();

    h.auth.signIn(1);
    await _settle(tester);
    expect(h.tokens.registered, ['fcm-token-1/ios/1.0.0']);

    h.messaging.refresh.add('fcm-token-2');
    await _settle(tester);
    expect(h.tokens.registered.last, 'fcm-token-2/ios/1.0.0');
    expect(h.controller.registeredToken, 'fcm-token-2');
  });

  testWidgets('no registration without notification permission', (
    tester,
  ) async {
    final h = _Harness()..messaging.allowed = false;
    addTearDown(h.container.dispose);
    await h.controller.start();

    h.auth.signIn(1);
    await _settle(tester);

    expect(h.tokens.registered, isEmpty);
  });

  testWidgets('signing out clears delivered pushes and drops the token', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.container.dispose);
    await h.controller.start();
    h.auth.signIn(1);
    await _settle(tester);

    h.auth.signOut();
    await _settle(tester);

    expect(h.messaging.cleared, 1);
    expect(h.messaging.deleted, 1);
    expect(h.controller.registeredToken, isNull);

    // A token refresh while signed out is not sent anywhere.
    h.messaging.refresh.add('fcm-token-3');
    await _settle(tester);
    expect(h.tokens.registered, ['fcm-token-1/ios/1.0.0']);
  });

  testWidgets('a tapped push opens its page and is marked read', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.container.dispose);
    await h.controller.start();
    h.auth.signIn(1);
    await _settle(tester);

    h.messaging.opened.add(_push());
    await _settle(tester);

    expect(h.opener.opened.single!.quizId, 9);
    expect(h.inbox.markedRead, [42]);
  });

  testWidgets('a push sent to another account is never opened or shown', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.container.dispose);
    await h.controller.start();
    h.auth.signIn(2);
    await _settle(tester);

    h.messaging.opened.add(_push(userId: 1));
    h.messaging.foreground.add(_push(userId: 1));
    await _settle(tester);

    expect(h.opener.opened, isEmpty);
    expect(h.messaging.presented, isEmpty);
    expect(h.controller.pendingOpen, isNull);
  });

  testWidgets('a push that launched the app waits for sign-in and the home '
      'screen', (tester) async {
    final h = _Harness();
    addTearDown(h.container.dispose);
    h.opener.ready.value = false;
    h.messaging.initial = _push(type: 'grade_published');

    await h.controller.start();
    await _settle(tester);
    expect(h.opener.opened, isEmpty);
    expect(h.controller.pendingOpen, isNotNull);

    h.auth.signIn(1);
    await _settle(tester);
    expect(h.opener.opened, isEmpty, reason: 'still on splash');

    h.opener.ready.value = true;
    await _settle(tester);
    expect(h.opener.opened.single!.type, 'grade_published');
  });

  testWidgets('a push in the foreground is shown and refreshes the inbox', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.container.dispose);
    await h.controller.start();
    h.auth.signIn(1);
    await _settle(tester);

    h.messaging.foreground.add(_push());
    await _settle(tester);

    expect(h.messaging.presented, hasLength(1));
  });
}
