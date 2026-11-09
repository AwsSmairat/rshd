import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_payload.dart';

/// The parts of Firebase Cloud Messaging the app uses, behind an interface so
/// the push flow can be tested without Firebase.
abstract class PushMessaging {
  String get platform;

  /// Asks for permission to show notifications; true when allowed.
  Future<bool> requestPermission();

  Future<String?> getToken();

  Future<void> deleteToken();

  Stream<String> get onTokenRefresh;

  /// Pushes that arrive while the app is open.
  Stream<PushMessage> get onForegroundMessage;

  /// Pushes the student tapped while the app was in the background.
  Stream<PushMessage> get onMessageOpenedApp;

  /// The push the student tapped to launch the app from closed.
  Future<PushMessage?> getInitialMessage();

  /// Shows a push that arrived while the app is open. iOS shows its own
  /// banner; Android needs a local notification.
  Future<void> presentForeground(PushMessage message);

  /// Removes delivered notifications (used when the account signs out).
  Future<void> clearDelivered();
}

/// Starts Firebase once, at launch, without holding up the first frame.
/// Push stays off (and the app works as before) if Firebase can't start.
abstract final class PushBootstrap {
  static Future<bool>? _ready;

  static void initialize(FirebaseOptions? options) {
    _ready ??= options == null ? Future.value(false) : _start(options);
  }

  /// Completes with whether Firebase is running.
  static Future<bool> get ready => _ready ?? Future.value(false);

  static Future<bool> _start(FirebaseOptions options) async {
    try {
      await Firebase.initializeApp(options: options);
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('Push disabled: Firebase failed to start: $error');
      return false;
    }
  }
}

class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging._();

  /// The messaging client once Firebase is running, or null without it.
  static Future<PushMessaging?> resolve() async =>
      await PushBootstrap.ready ? FirebasePushMessaging._() : null;

  static const androidChannel = AndroidNotificationChannel(
    'rshd_general',
    'إشعارات رشد',
    description: 'المحاضرات والواجبات والاختبارات والنتائج والرسائل والإعلانات',
    importance: Importance.high,
  );

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final StreamController<PushMessage> _localTaps =
      StreamController<PushMessage>.broadcast();
  bool _localReady = false;

  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';

  /// Android only: the channel pushes use, and taps on the local
  /// notifications shown in the foreground. iOS needs neither.
  Future<void> _ensureLocal() async {
    if (_localReady || !Platform.isAndroid) return;
    _localReady = true;
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_rshd'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final message = PushMessage.decode(response.payload);
        if (message != null) _localTaps.add(message);
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureLocal();
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // Show the system banner for pushes that arrive while the app is open.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async {
    if (Platform.isIOS) {
      // FCM needs the APNs token first; it can lag a moment behind launch.
      for (var attempt = 0; attempt < 5; attempt++) {
        if (await _messaging.getAPNSToken() != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (await _messaging.getAPNSToken() == null) return null;
    }
    // The server sends through FCM HTTP v1 to a registration token, so the
    // token API is used rather than the newer installation-ID (FID) one.
    // ignore: deprecated_member_use
    return _messaging.getToken();
  }

  @override
  // ignore: deprecated_member_use
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_fromRemote);

  @override
  Stream<PushMessage> get onMessageOpenedApp => StreamGroupLite.merge([
    FirebaseMessaging.onMessageOpenedApp.map(_fromRemote),
    _localTaps.stream,
  ]);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final remote = await _messaging.getInitialMessage();
    if (remote != null) return _fromRemote(remote);

    if (Platform.isAndroid) {
      await _ensureLocal();
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        return PushMessage.decode(launch!.notificationResponse?.payload);
      }
    }
    return null;
  }

  @override
  Future<void> presentForeground(PushMessage message) async {
    if (!Platform.isAndroid) return;
    await _ensureLocal();
    final id = int.tryParse('${message.data['notification_id'] ?? ''}');
    await _local.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: message.title,
      body: message.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF0B1F3A),
          styleInformation: BigTextStyleInformation(message.body ?? ''),
        ),
      ),
      payload: message.encode(),
    );
  }

  @override
  Future<void> clearDelivered() async {
    if (!Platform.isAndroid) return;
    await _ensureLocal();
    await _local.cancelAll();
  }

  static PushMessage _fromRemote(RemoteMessage remote) => PushMessage(
    data: Map<String, dynamic>.from(remote.data),
    title: remote.notification?.title,
    body: remote.notification?.body,
  );
}

/// Merges a few broadcast streams (no extra package needed).
abstract final class StreamGroupLite {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late final StreamController<T> controller;
    final subscriptions = <StreamSubscription<T>>[];
    controller = StreamController<T>.broadcast(
      onListen: () {
        for (final stream in streams) {
          subscriptions.add(stream.listen(controller.add));
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      },
    );
    return controller.stream;
  }
}
