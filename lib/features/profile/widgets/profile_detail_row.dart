import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/app_strings.dart';

class ProfileDetailRow extends StatelessWidget {
  const ProfileDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final verticalPadding = dense ? 6.0 : 12.0;
    final iconSize = dense ? 34.0 : 40.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: AppColors.of(context).background,
                  borderRadius: BorderRadius.circular(dense ? 10 : 12),
                ),
                child: Icon(
                  icon,
                  color: dense
                      ? AppColors.of(context).darkGold
                      : AppColors.of(context).primary,
                  size: dense ? 18 : 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(AppStrings.of(context).t(label),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: dense ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).text,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(AppStrings.of(context).t(value),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: dense ? 12 : 13,
                    color: valueColor ?? AppColors.of(context).textMuted,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: const Color(0xFFE5E7EB).withValues(alpha: 0.9),
          ),
      ],
    );
  }
}
