import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.accent.withValues(alpha: 0.35),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'أو',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.accent.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}
