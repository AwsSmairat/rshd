import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native screen-protection events (no sensitive payloads).
enum ScreenProtectionEventType {
  captureStarted,
  captureEnded,
  screenshotTaken,
}

class ScreenProtectionEvent {
  const ScreenProtectionEvent(this.type);

  final ScreenProtectionEventType type;
}

abstract class ScreenProtectionPlatform {
  Future<void> enableSecure();
  Future<void> disableSecure();
  Future<bool> isScreenCaptured();
  Stream<ScreenProtectionEvent> get events;

  static ScreenProtectionPlatform instance = MethodChannelScreenProtectionPlatform();
}

class MethodChannelScreenProtectionPlatform implements ScreenProtectionPlatform {
  MethodChannelScreenProtectionPlatform({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel('com.rshd/screen_protection'),
        _eventChannel = eventChannel ??
            const EventChannel('com.rshd/screen_protection/events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  Stream<ScreenProtectionEvent>? _events;

  @override
  Future<void> enableSecure() async {
    try {
      await _methodChannel.invokeMethod<void>('enableSecure');
    } on PlatformException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'screen_protection_platform',
          context: ErrorDescription('while enabling secure screen'),
        ),
      );
    }
  }

  @override
  Future<void> disableSecure() async {
    try {
      await _methodChannel.invokeMethod<void>('disableSecure');
    } on PlatformException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'screen_protection_platform',
          context: ErrorDescription('while disabling secure screen'),
        ),
      );
    }
  }

  @override
  Future<bool> isScreenCaptured() async {
    try {
      final captured =
          await _methodChannel.invokeMethod<bool>('isScreenCaptured');
      return captured ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<ScreenProtectionEvent> get events {
    return _events ??= _eventChannel.receiveBroadcastStream().map(_parseEvent).where(
      (event) => event != null,
    ).map((event) => event!);
  }

  ScreenProtectionEvent? _parseEvent(dynamic raw) {
    if (raw is! Map) return null;
    final typeName = raw['type']?.toString();
    return switch (typeName) {
      'capture_started' => const ScreenProtectionEvent(
          ScreenProtectionEventType.captureStarted,
        ),
      'capture_ended' => const ScreenProtectionEvent(
          ScreenProtectionEventType.captureEnded,
        ),
      'screenshot_taken' => const ScreenProtectionEvent(
          ScreenProtectionEventType.screenshotTaken,
        ),
      _ => null,
    };
  }
}
