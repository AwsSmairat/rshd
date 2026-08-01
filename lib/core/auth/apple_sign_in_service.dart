import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInException implements Exception {
  AppleSignInException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppleSignInResult {
  const AppleSignInResult({
    required this.identityToken,
    this.fullName,
  });

  final String identityToken;
  final String? fullName;
}

class AppleSignInService {
  bool get isSupported => Platform.isIOS || Platform.isMacOS;

  Future<AppleSignInResult?> signIn() async {
    if (!isSupported) {
      return null;
    }

    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw AppleSignInException(
        'تسجيل الدخول عبر Apple غير متاح على هذا الجهاز. '
        'تأكد من تسجيل الدخول إلى iCloud على المحاكي أو الجهاز.',
      );
    }

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return null;
      }

      throw AppleSignInException(_mapAuthorizationError(error));
    }

    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw AppleSignInException(
        'تعذر الحصول على رمز Apple. أعد المحاولة أو استخدم طريقة أخرى للتسجيل.',
      );
    }

    final givenName = credential.givenName?.trim();
    final familyName = credential.familyName?.trim();
    final fullName = [
      if (givenName != null && givenName.isNotEmpty) givenName,
      if (familyName != null && familyName.isNotEmpty) familyName,
    ].join(' ').trim();

    return AppleSignInResult(
      identityToken: identityToken,
      fullName: fullName.isEmpty ? null : fullName,
    );
  }

  String _mapAuthorizationError(SignInWithAppleAuthorizationException error) {
    switch (error.code) {
      case AuthorizationErrorCode.failed:
        return 'فشل تسجيل الدخول عبر Apple. تأكد من تفعيل Sign in with Apple '
            'في Xcode لـ Bundle ID: com.example.rshd.';
      case AuthorizationErrorCode.invalidResponse:
        return 'استجابة Apple غير صالحة. أعد المحاولة.';
      case AuthorizationErrorCode.notHandled:
        return 'تعذر معالجة طلب Apple. أعد تشغيل التطبيق وحاول مجدداً.';
      case AuthorizationErrorCode.notInteractive:
        return 'تسجيل الدخول عبر Apple يتطلب تفاعلاً من المستخدم. حاول مجدداً.';
      case AuthorizationErrorCode.canceled:
        return 'تم إلغاء تسجيل الدخول عبر Apple.';
      case AuthorizationErrorCode.unknown:
      default:
        return 'حدث خطأ غير متوقع من Apple. تأكد من تسجيل الدخول إلى iCloud '
            'على الجهاز.';
    }
  }
}

final appleSignInServiceProvider = Provider<AppleSignInService>((ref) {
  return AppleSignInService();
});
