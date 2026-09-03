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
            color: AppColors.of(context).textMuted.withValues(alpha: 0.95),
          ),
        ),
        GestureDetector(
          onTap: onLoginTap,
          child: Text(
            'سجل الدخول',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).darkGold,
            ),
          ),
        ),
      ],
    );
  }
}
