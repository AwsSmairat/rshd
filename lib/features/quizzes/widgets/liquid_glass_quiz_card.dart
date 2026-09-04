import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/quiz_model.dart';
import 'quiz_icon_helper.dart';
import 'quiz_icon_panel.dart';
import 'quiz_status_badge.dart';
import '../../../core/l10n/app_strings.dart';

class LiquidGlassQuizCard extends StatelessWidget {
  const LiquidGlassQuizCard({
    super.key,
    required this.quiz,
    required this.onTap,
  });

  final QuizModel quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = QuizIconHelper.iconFor(
      title: quiz.title,
      subjectTitle: quiz.subjectTitle,
    );

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      fillOpacity: 0.38,
      borderOpacity: 0.7,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.04,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(AppStrings.of(context).t(quiz.title),
                        style: AppTextStyles.titleOf(context).copyWith(
                          fontSize: 17,
                          height: 1.3,
                          color: AppColors.of(context).primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.of(
                              context,
                            ).accent.withValues(alpha: 0.45),
                            AppColors.of(context).darkGold,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (quiz.subjectTitle != null &&
                    quiz.subjectTitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _MetaRow(icon: icon, text: quiz.subjectTitle!),
                ],
                if (quiz.lessonTitle != null &&
                    quiz.lessonTitle!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.school_outlined,
                    text: AppStrings.of(context).t('الدرس: ${quiz.lessonTitle!}'),
                  ),
                ],
                if (quiz.questionsCount != null ||
                    quiz.durationMinutes != null) ...[
                  const SizedBox(height: 10),
                  _QuizStatsBar(
                    questionsCount: quiz.questionsCount,
                    durationMinutes: quiz.durationMinutes,
                  ),
                ],
                const SizedBox(height: 12),
                QuizStatusBadge(quiz: quiz),
              ],
            ),
          ),
          const SizedBox(width: 12),
          QuizIconPanel(icon: icon),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.of(context).primary.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.of(context).darkGold),
        const SizedBox(width: 6),
        Expanded(
          child: Text(AppStrings.of(context).t(text),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 13, color: AppColors.of(context).textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _QuizStatsBar extends StatelessWidget {
  const _QuizStatsBar({
    required this.questionsCount,
    required this.durationMinutes,
  });

  final int? questionsCount;
  final int? durationMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.of(context).textMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          if (questionsCount != null)
            _StatChip(
              icon: Icons.format_list_numbered_rounded,
              label: AppStrings.of(context).t('$questionsCount أسئلة'),
            ),
          if (durationMinutes != null)
            _StatChip(
              icon: Icons.schedule_outlined,
              label: AppStrings.of(context).t('المدة: $durationMinutes دقيقة'),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.of(context).darkGold),
        const SizedBox(width: 4),
        Text(AppStrings.of(context).t(label),
          style: AppTextStyles.bodyOf(
            context,
          ).copyWith(fontSize: 12, color: AppColors.of(context).textMuted),
        ),
      ],
    );
  }
}
