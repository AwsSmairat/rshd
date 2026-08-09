import 'package:flutter/foundation.dart';

/// Debug-only startup timing marks (milliseconds since process start).
class StartupTiming {
  StartupTiming._();

  static final Stopwatch _stopwatch = Stopwatch();
  static final Map<String, int> _marks = <String, int>{};
  static bool _started = false;

  static void ensureStarted() {
    if (_started) {
      return;
    }
    _started = true;
    _stopwatch.start();
  }

  static void mark(String label) {
    if (!kDebugMode) {
      return;
    }
    ensureStarted();
    final elapsed = _stopwatch.elapsedMilliseconds;
    _marks[label] = elapsed;
    debugPrint('[startup_timing] $label=${elapsed}ms');
  }

  static int? elapsedMs(String label) => _marks[label];

  static Map<String, int> get marks => Map.unmodifiable(_marks);

  @visibleForTesting
  static void resetForTests() {
    _marks.clear();
    _started = false;
    _stopwatch.reset();
  }
}
