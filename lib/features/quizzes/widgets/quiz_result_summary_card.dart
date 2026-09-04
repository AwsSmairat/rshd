import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'quiz_score_helper.dart';
import 'result_progress_circle.dart';
import '../../../core/l10n/app_strings.dart';

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
    final grade = AppStrings.of(context).t(QuizScoreHelper.gradeLabel(score));
    final gradeColor = QuizScoreHelper.gradeColor(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.of(context).primary,
            AppColors.of(context).secondaryNavy,
          ],
        ),
        border: Border.all(
          color: AppColors.of(context).accent.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).primary.withValues(alpha: 0.18),
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
                Text(AppStrings.of(context).t(title),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(AppStrings.of(context).t(grade),
                  style: AppTextStyles.titleOf(
                    context,
                  ).copyWith(fontSize: 24, color: gradeColor),
                ),
                if (showEncouragement) ...[
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.of(context).t(QuizScoreHelper.encouragement(score)),
                    style: AppTextStyles.bodyOf(context).copyWith(
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
