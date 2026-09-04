import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';

class RegisterLegalLinks extends StatelessWidget {
  const RegisterLegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: AppColors.of(context).textMuted.withValues(alpha: 0.95),
        ),
        children: [
          TextSpan(text: AppStrings.of(context).t('بإنشاء الحساب أنت توافق على ')),
          TextSpan(
            text: AppStrings.of(context).t('شروط الاستخدام'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).darkGold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push(AppRoutes.termsAndConditions),
          ),
          TextSpan(text: AppStrings.of(context).t(' و')),
          TextSpan(
            text: AppStrings.of(context).t('سياسة الخصوصية'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).darkGold,
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
