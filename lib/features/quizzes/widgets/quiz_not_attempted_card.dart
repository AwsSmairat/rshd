import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/l10n/app_strings.dart';

class QuizNotAttemptedCard extends StatelessWidget {
  const QuizNotAttemptedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(18),
      fillOpacity: 0.34,
      borderOpacity: 0.62,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.of(context).t('لم تقم بحل هذا الاختبار بعد'),
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(AppStrings.of(context).t('ابدأ الاختبار لعرض نتيجتك هنا'),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 13, color: AppColors.of(context).textMuted),
          ),
        ],
      ),
    );
  }
}
