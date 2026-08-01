import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'quiz_score_helper.dart';
import 'result_progress_circle.dart';

class QuizResultSummaryCard extends StatelessWidget {
  const QuizResultSummaryCard({
    super.key,
    required this.score,
    this.title = 'نتيجتك الأخيرة',
    this.showEncouragement = true,
  });

  final double score;
  final String title;
  final bool showEncouragement;

  @override
  Widget build(BuildContext context) {
    final grade = QuizScoreHelper.gradeLabel(score);
    final gradeColor = QuizScoreHelper.gradeColor(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondaryNavy,
          ],
        ),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  grade,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 24,
                    color: gradeColor,
                  ),
                ),
                if (showEncouragement) ...[
                  const SizedBox(height: 6),
                  Text(
                    QuizScoreHelper.encouragement(score),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 1,
            height: 96,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white.withValues(alpha: 0.18),
          ),
          ResultProgressCircle(
            progress: QuizScoreHelper.normalizedProgress(score),
            centerText: QuizScoreHelper.formatScore(score),
          ),
        ],
      ),
    );
  }
}
