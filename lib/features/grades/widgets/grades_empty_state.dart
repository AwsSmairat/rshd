import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';

class GradesEmptyState extends StatelessWidget {
  const GradesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      fillOpacity: 0.35,
      borderOpacity: 0.65,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.06,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.of(context).accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: AppColors.of(context).darkGold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد درجات حالياً',
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر درجاتك هنا بعد تقييم الواجبات والاختبارات',
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: 13,
              height: 1.5,
              color: AppColors.of(context).textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
