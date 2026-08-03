import 'dart:io';

import 'package:flutter/foundation.dart';

/// Central configuration for API and environment settings.
class AppConfig {
  AppConfig._();

  /// Change this port to match your Laravel server (`php artisan serve --port=8765`).
  static const int apiPort = 8765;

  /// Override for physical devices during development (e.g. `http://192.168.1.10:8765/api/v1`).
  static const String? deviceBaseUrlOverride = null;

  static String get baseUrl {
    if (deviceBaseUrlOverride != null && deviceBaseUrlOverride!.isNotEmpty) {
      return deviceBaseUrlOverride!;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$apiPort/api/v1';
    }

    return 'http://127.0.0.1:$apiPort/api/v1';
  }

  static String get appOrigin {
    if (deviceBaseUrlOverride != null && deviceBaseUrlOverride!.isNotEmpty) {
      return deviceBaseUrlOverride!.replaceAll('/api/v1', '');
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$apiPort';
    }

    return 'http://127.0.0.1:$apiPort';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static bool get enableNetworkLogs => kDebugMode;

  /// Web OAuth client ID — required on Android to obtain an ID token.
  /// Set via `--dart-define=GOOGLE_WEB_CLIENT_ID=...` or replace the default.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// iOS OAuth client ID — set in Info.plist (GIDClientID) and optionally here.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  /// Returns `true` when [clientId] looks like a real Google OAuth client ID.
  static bool isValidGoogleClientId(String? clientId) {
    if (clientId == null) {
      return false;
    }

    final trimmed = clientId.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final lower = trimmed.toLowerCase();
    if (lower.contains('your_') ||
        lower.contains('placeholder') ||
        lower.contains('example') ||
        lower.contains('xxx')) {
      return false;
    }

    const suffix = '.apps.googleusercontent.com';
    if (!lower.endsWith(suffix)) {
      return false;
    }

    final prefix = trimmed.substring(0, trimmed.length - suffix.length);
    if (prefix.length < 12 || !prefix.contains('-')) {
      return false;
    }

    return true;
  }

  /// Converts an iOS Google client ID to the reversed URL scheme form.
  static String? reversedIosClientId(String? iosClientId) {
    if (!isValidGoogleClientId(iosClientId)) {
      return null;
    }

    const suffix = '.apps.googleusercontent.com';
    final trimmed = iosClientId!.trim();
    final prefix = trimmed.substring(0, trimmed.length - suffix.length);

    return 'com.googleusercontent.apps.$prefix';
  }

  /// Whether Google Sign-In has real OAuth client IDs (not example placeholders).
  static bool get isGoogleSignInConfigured {
    if (!isValidGoogleClientId(googleWebClientId)) {
      return false;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return isValidGoogleClientId(googleIosClientId);
    }

    return true;
  }

  static const String googleSignInSetupHint =
      'يجب إنشاء OAuth Client IDs من Google Cloud Console ووضع القيم '
      'الحقيقية في oauth_defines.json (ليس YOUR_WEB_CLIENT_ID). '
      'ثم شغّل: ./tool/sync_oauth_config.sh && flutter run '
      '--dart-define-from-file=oauth_defines.json';
}
