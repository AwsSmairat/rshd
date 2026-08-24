import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterLegalLinks extends StatelessWidget {
  const RegisterLegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: AppColors.textMuted.withValues(alpha: 0.95),
        ),
        children: [
          const TextSpan(text: 'بإنشاء الحساب أنت توافق على '),
          TextSpan(
            text: 'شروط الاستخدام',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.darkGold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push(AppRoutes.termsAndConditions),
          ),
          const TextSpan(text: ' و'),
          TextSpan(
            text: 'سياسة الخصوصية',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.darkGold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push(AppRoutes.privacyPolicy),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }
}
