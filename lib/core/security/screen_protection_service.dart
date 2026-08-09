import 'dart:async';

import 'package:flutter/widgets.dart';

import 'screen_protection_platform.dart';
import 'screen_protection_state.dart';
import 'security_event_logger.dart';

/// Central coordinator for secure-content routes with reference counting.
///
/// ## Platform behavior
/// - **Android**: Screenshot/recording blocking via native `FLAG_SECURE` while
///   any protected scope is active. Re-applied on resume and window focus.
/// - **iOS screenshot prevention**: NOT available through official Apple APIs.
///   Manual screenshots cannot be blocked; we only log a local debug event.
/// - **iOS screen recording/mirroring**: Detected via `UIScreen.isCaptured`.
///   Protected content is hidden behind an overlay and media playback pauses.
/// - **App Switcher privacy**: Flutter privacy overlay on inactive/background
///   lifecycle while protection is active (iOS relies on this; Android uses
///   `FLAG_SECURE` for recent-apps preview when supported by the OS).
/// - **Physical external camera recording**: Cannot be prevented on any platform.
class ScreenProtectionService extends ChangeNotifier
    with WidgetsBindingObserver {
  ScreenProtectionService({
    ScreenProtectionPlatform? platform,
    SecurityEventLogger? securityLogger,
  }) : _platform = platform ?? ScreenProtectionPlatform.instance,
       _securityLogger = securityLogger ?? const SecurityEventLogger() {
    WidgetsBinding.instance.addObserver(this);
  }

  final ScreenProtectionPlatform _platform;
  final SecurityEventLogger _securityLogger;
  final Set<String> _activeScopes = <String>{};
  StreamSubscription<ScreenProtectionEvent>? _eventsSub;
  bool _disposed = false;

  ScreenProtectionState _state = const ScreenProtectionState();

  ScreenProtectionState get state => _state;

  bool get isProtectionActive => _state.isProtectionActive;
  bool get shouldHideContent => _state.shouldHideContent;
  bool get isScreenCaptured => _state.isScreenCaptured;

  Future<void> acquire(String scopeId) async {
    if (_activeScopes.contains(scopeId)) return;

    _activeScopes.add(scopeId);
    if (_activeScopes.length == 1) {
      await _platform.enableSecure();
      final captured = await _platform.isScreenCaptured();
      _eventsSub ??= _platform.events.listen(_onPlatformEvent);
      _state = _state.copyWith(
        activeScopeCount: _activeScopes.length,
        isScreenCaptured: captured,
      );
    } else {
      _state = _state.copyWith(activeScopeCount: _activeScopes.length);
    }
    _notifyIfAlive();
  }

  Future<void> release(String scopeId, {bool silent = false}) async {
    if (!_activeScopes.remove(scopeId)) return;

    if (_activeScopes.isEmpty) {
      await _eventsSub?.cancel();
      _eventsSub = null;
      await _platform.disableSecure();
      _state = const ScreenProtectionState();
    } else {
      _state = _state.copyWith(activeScopeCount: _activeScopes.length);
    }
    if (!silent) {
      _notifyIfAlive();
    }
  }

  void _onPlatformEvent(ScreenProtectionEvent event) {
    _securityLogger.log(event.type);
    switch (event.type) {
      case ScreenProtectionEventType.captureStarted:
        _state = _state.copyWith(isScreenCaptured: true);
      case ScreenProtectionEventType.captureEnded:
        _state = _state.copyWith(isScreenCaptured: false);
      case ScreenProtectionEventType.screenshotTaken:
        break;
    }
    _notifyIfAlive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isProtectionActive) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (!_state.showPrivacyOverlay) {
          _state = _state.copyWith(showPrivacyOverlay: true);
          _notifyIfAlive();
        }
        return;
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearPrivacyOverlayForResume();
        });
        return;
      case AppLifecycleState.detached:
        return;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_eventsSub?.cancel());
    super.dispose();
  }

  @visibleForTesting
  void clearPrivacyOverlayForResume() {
    if (_disposed || !isProtectionActive || !_state.showPrivacyOverlay) return;
    _state = _state.copyWith(showPrivacyOverlay: false);
    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}

/// Testing helper to reset singleton platform between tests.
class FakeScreenProtectionPlatform implements ScreenProtectionPlatform {
  FakeScreenProtectionPlatform({this.captured = false});

  bool secureEnabled = false;
  bool captured;
  final StreamController<ScreenProtectionEvent> _controller =
      StreamController<ScreenProtectionEvent>.broadcast();

  @override
  Future<void> disableSecure() async {
    secureEnabled = false;
  }

  @override
  Future<void> enableSecure() async {
    secureEnabled = true;
  }

  @override
  Stream<ScreenProtectionEvent> get events => _controller.stream;

  @override
  Future<bool> isScreenCaptured() async => captured;

  void emit(ScreenProtectionEvent event) {
    if (event.type == ScreenProtectionEventType.captureStarted) {
      captured = true;
    } else if (event.type == ScreenProtectionEventType.captureEnded) {
      captured = false;
    }
    _controller.add(event);
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
