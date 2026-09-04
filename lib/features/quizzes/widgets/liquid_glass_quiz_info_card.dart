import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/quiz_model.dart';
import 'quiz_icon_helper.dart';
import 'quiz_icon_panel.dart';
import '../../../core/l10n/app_strings.dart';

class LiquidGlassQuizInfoCard extends StatelessWidget {
  const LiquidGlassQuizInfoCard({super.key, required this.quiz});

  final QuizModel quiz;

  @override
  Widget build(BuildContext context) {
    final icon = quiz.isCompleted
        ? Icons.emoji_events_outlined
        : QuizIconHelper.iconFor(
            title: quiz.title,
            subjectTitle: quiz.subjectTitle,
          );

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(26),
      padding: const EdgeInsets.all(20),
      fillOpacity: 0.38,
      borderOpacity: 0.7,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.04,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.of(context).t(quiz.title),
                  style: AppTextStyles.titleOf(context).copyWith(
                    fontSize: 20,
                    height: 1.3,
                    color: AppColors.of(context).primary,
                  ),
                ),
                if (quiz.description != null &&
                    quiz.description!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoLine(
                    icon: Icons.description_outlined,
                    label: AppStrings.of(context).t('الوصف'),
                    value: quiz.description!,
                  ),
                ],
                if (quiz.subjectTitle != null &&
                    quiz.subjectTitle!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoLine(
                    icon: Icons.menu_book_outlined,
                    label: AppStrings.of(context).t('المادة'),
                    value: quiz.subjectTitle!,
                  ),
                ],
                if (quiz.lessonTitle != null &&
                    quiz.lessonTitle!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoLine(
                    icon: Icons.school_outlined,
                    label: AppStrings.of(context).t('الدرس'),
                    value: quiz.lessonTitle!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 72, child: QuizIconPanel(icon: icon)),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.of(context).darkGold),
            const SizedBox(width: 6),
            Text(AppStrings.of(context).t(label),
              style: AppTextStyles.bodyOf(context).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).darkGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(AppStrings.of(context).t(value),
          style: AppTextStyles.bodyOf(context).copyWith(
            fontSize: 14,
            height: 1.45,
            color: AppColors.of(context).primary,
          ),
        ),
      ],
    );
  }
}
