import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/security/sensitive_data_redactor.dart';

typedef VideoProgressSyncCallback =
    Future<void> Function({
      required int currentPositionSeconds,
      required int durationSeconds,
      bool showSuccessMessage,
    });

/// Sends video watch progress every 15 seconds and once on dispose.
class VideoProgressTracker {
  VideoProgressTracker({required this.durationSeconds, required this.onSync});

  final int durationSeconds;
  final VideoProgressSyncCallback onSync;

  Timer? _periodicTimer;
  int _currentPositionSeconds = 0;
  bool _hasStarted = false;
  bool _disposed = false;
  int _lastSentPosition = -1;

  int get currentPositionSeconds => _currentPositionSeconds;

  int get completionPercentage {
    if (durationSeconds <= 0 || _currentPositionSeconds <= 0) {
      return 0;
    }

    return ((_currentPositionSeconds / durationSeconds) * 100)
        .clamp(0, 100)
        .round();
  }

  void updatePosition(Duration position, {required bool isPlaying}) {
    if (_disposed) {
      return;
    }

    _currentPositionSeconds = position.inSeconds;

    if (isPlaying && _currentPositionSeconds > 0) {
      _hasStarted = true;
      _ensurePeriodicTimer();
    }
  }

  void _ensurePeriodicTimer() {
    _periodicTimer ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_sendProgress(force: true)),
    );
  }

  Future<void> flush({bool showSuccessMessage = false}) async {
    await _sendProgress(showSuccessMessage: showSuccessMessage, force: true);
  }

  Future<void> _sendProgress({
    bool showSuccessMessage = false,
    bool force = false,
  }) async {
    if (_disposed || !_hasStarted || _currentPositionSeconds <= 0) {
      return;
    }

    if (!force &&
        !showSuccessMessage &&
        _currentPositionSeconds == _lastSentPosition) {
      return;
    }

    _lastSentPosition = _currentPositionSeconds;

    try {
      await onSync(
        currentPositionSeconds: _currentPositionSeconds,
        durationSeconds: durationSeconds,
        showSuccessMessage: showSuccessMessage,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'VideoProgressTracker sync failed: ${SensitiveDataRedactor.redactString(error.toString())}',
        );
        debugPrint('$stackTrace');
      }
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    _periodicTimer?.cancel();
    _periodicTimer = null;

    final shouldFlush = _hasStarted && _currentPositionSeconds > 0;
    _disposed = true;

    if (shouldFlush) {
      unawaited(
        onSync(
          currentPositionSeconds: _currentPositionSeconds,
          durationSeconds: durationSeconds,
          showSuccessMessage: true,
        ),
      );
    }
  }
}
