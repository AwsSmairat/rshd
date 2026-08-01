import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';

class AssignmentSectionCard extends StatelessWidget {
  const AssignmentSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      fillOpacity: 0.38,
      borderOpacity: 0.7,
      blurSigma: 16,
      tintColor: AppColors.accent,
      tintOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.darkGold),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
