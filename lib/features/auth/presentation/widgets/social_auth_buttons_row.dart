import 'package:flutter/material.dart';

import 'apple_sign_in_button.dart';
import 'google_sign_in_button.dart';

class SocialAuthButtonsRow extends StatelessWidget {
  const SocialAuthButtonsRow({
    super.key,
    required this.onGooglePressed,
    this.onApplePressed,
    this.isLoading = false,
    this.showApple = true,
  });

  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final bool isLoading;
  final bool showApple;

  @override
  Widget build(BuildContext context) {
    if (!showApple) {
      return GoogleSignInButton(
        label: 'تسجيل الدخول باستخدام Google',
        isLoading: isLoading,
        onPressed: onGooglePressed,
      );
    }

    return Row(
      children: [
        Expanded(
          child: GoogleSignInButton(
            label: 'Google',
            compact: true,
            isLoading: isLoading,
            onPressed: onGooglePressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppleSignInButton(
            label: 'Apple',
            compact: true,
            isLoading: isLoading,
            onPressed: onApplePressed,
          ),
        ),
      ],
    );
  }
}
