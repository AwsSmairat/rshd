import 'package:flutter/foundation.dart';

/// Validates production API configuration at startup.
class ReleaseEnvironmentGuard {
  ReleaseEnvironmentGuard._();

  static const insecureHosts = {
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
    '0.0.0.0',
  };

  static void assertProductionApiUrl(String url) {
    if (!kReleaseMode) {
      return;
    }

    if (!isProductionSafeUrl(url)) {
      throw StateError(
        'Release build API URL failed production safety checks.',
      );
    }
  }

  /// Pure validation helper (testable in debug/profile builds).
  static bool isProductionSafeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return false;
    }

    if (uri.scheme != 'https') {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (insecureHosts.contains(host)) {
      return false;
    }

    return !url.toLowerCase().startsWith('http://');
  }

  static void assertReleaseConfiguration({required String baseUrl}) {
    if (!kReleaseMode) {
      return;
    }

    if (baseUrl.trim().isEmpty) {
      throw StateError(
        'Release build requires --dart-define=API_BASE_URL=https://your-api/api/v1',
      );
    }

    assertProductionApiUrl(baseUrl);
  }
}
