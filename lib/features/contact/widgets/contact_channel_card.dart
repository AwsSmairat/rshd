import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';

class ContactChannelCard extends StatelessWidget {
  const ContactChannelCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.isEnabled = true,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.of(context).darkGold;
    final disabled = !isEnabled;

    return Semantics(
      button: isEnabled,
      enabled: isEnabled,
      label: '$title: $value',
      child: LiquidGlassSurface(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(18),
        fillOpacity: disabled ? 0.22 : 0.38,
        borderOpacity: disabled ? 0.35 : 0.65,
        blurSigma: 16,
        tintColor: AppColors.of(context).accent,
        tintOpacity: disabled ? 0.02 : 0.04,
        onTap: isEnabled ? onTap : null,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: disabled ? 0.08 : 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: disabled ? AppColors.of(context).textMuted : accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyOf(context).copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: AppTextStyles.bodyOf(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? AppColors.of(context).textMuted
                          : AppColors.of(context).primary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled)
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.of(context).primary.withValues(alpha: 0.45),
              ),
          ],
        ),
      ),
    );
  }
}
