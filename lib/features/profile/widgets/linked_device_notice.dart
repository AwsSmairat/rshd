import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LinkedDeviceNotice extends StatelessWidget {
  const LinkedDeviceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.of(context).accent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppColors.of(context).darkGold,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(AppStrings.of(context).t(AppStrings.of(context).linkedDeviceNotice),
              style: AppTextStyles.bodyOf(context).copyWith(
                fontSize: 13,
                height: 1.45,
                color: AppColors.of(context).primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
