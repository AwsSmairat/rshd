import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/l10n/app_strings.dart';

class DepartmentCard extends StatelessWidget {
  const DepartmentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.icon,
    required this.titleColor,
    required this.badgeColor,
    required this.iconBackground,
    required this.onTap,
    this.width,
    this.height,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final IconData icon;
  final Color titleColor;
  final Color badgeColor;
  final Color iconBackground;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      width: width,
      height: height ?? 230,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(16),
      tintColor: titleColor,
      tintOpacity: 0.05,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: titleColor, size: 26),
          ),
          const SizedBox(height: 14),
          Text(AppStrings.of(context).t(title),
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(AppStrings.of(context).t(subtitle),
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: 12,
              height: 1.45,
              color: AppColors.of(context).textMuted,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(AppStrings.of(context).t(countLabel),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
