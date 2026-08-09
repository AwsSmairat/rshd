import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class RegisterLoginLink extends StatelessWidget {
  const RegisterLoginLink({super.key, required this.onLoginTap});

  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'لديك حساب بالفعل؟ ',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted.withValues(alpha: 0.95),
          ),
        ),
        GestureDetector(
          onTap: onLoginTap,
          child: const Text(
            'سجل الدخول',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGold,
            ),
          ),
        ),
      ],
    );
  }
}
