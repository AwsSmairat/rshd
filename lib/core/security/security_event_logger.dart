import 'package:flutter/foundation.dart';

import 'screen_protection_platform.dart';

/// Local-only security signals. Never logs URLs, tokens, or personal data.
class SecurityEventLogger {
  const SecurityEventLogger();

  void log(ScreenProtectionEventType type) {
    if (!kDebugMode) return;
    final label = switch (type) {
      ScreenProtectionEventType.captureStarted => 'screen_recording_detected',
      ScreenProtectionEventType.captureEnded => 'screen_recording_ended',
      ScreenProtectionEventType.screenshotTaken => 'screenshot_detected',
    };
    debugPrint('[security_event] $label');
  }
}
