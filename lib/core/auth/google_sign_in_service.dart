import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

class GoogleSignInConfigurationException implements Exception {
  GoogleSignInConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: AppConfig.googleWebClientId.isEmpty
                  ? null
                  : AppConfig.googleWebClientId,
              clientId: AppConfig.googleIosClientId.isEmpty
                  ? null
                  : AppConfig.googleIosClientId,
            );

  final GoogleSignIn _googleSignIn;

  bool get isConfigured => AppConfig.isGoogleSignInConfigured;

  Future<String?> signInAndGetIdToken() async {
    if (!isConfigured) {
      throw GoogleSignInConfigurationException(
        'تسجيل الدخول عبر Google غير جاهز بعد.\n'
        'ضع Client IDs الحقيقية من Google Cloud Console في oauth_defines.json '
        'ثم شغّل:\n'
        './tool/sync_oauth_config.sh\n'
        'flutter run --dart-define-from-file=oauth_defines.json',
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw GoogleSignInConfigurationException(
          'تعذر الحصول على رمز Google. تأكد من إضافة Web Client ID '
          'في oauth_defines.json و OAuth.xcconfig.',
        );
      }

      return idToken;
    } on PlatformException catch (error) {
      throw GoogleSignInConfigurationException(
        _mapPlatformError(error),
      );
    }
  }

  String _mapPlatformError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code.contains('sign_in_canceled') || code.contains('canceled')) {
      return 'تم إلغاء تسجيل الدخول عبر Google.';
    }

    if (message.contains('gidclientid') ||
        message.contains('no active configuration') ||
        code.contains('configuration')) {
      return 'إعداد Google غير مكتمل على iOS.\n${AppConfig.googleSignInSetupHint}';
    }

    if (message.contains('url') || message.contains('scheme')) {
      return 'رابط العودة من Google غير مُعدّ.\n${AppConfig.googleSignInSetupHint}';
    }

    return 'تعذر تسجيل الدخول عبر Google. (${error.code})';
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});
