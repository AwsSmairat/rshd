import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';

class QuizSubmissionSuccessCard extends StatelessWidget {
  const QuizSubmissionSuccessCard({super.key, required this.quizTitle});

  final String quizTitle;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      fillOpacity: 0.38,
      borderOpacity: 0.7,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.04,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFDCFCE7),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF16A34A),
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'تم تسليم الاختبار',
            style: AppTextStyles.titleOf(
              context,
            ).copyWith(fontSize: 20, color: AppColors.of(context).primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            quizTitle,
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(color: AppColors.of(context).textMuted),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
