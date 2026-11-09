import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/content_direction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/quiz_question_model.dart';
import 'quiz_answer_option.dart';
import 'quiz_text_cleanup.dart';

/// A question and its answers. The question is laid out in its own reading
/// direction (English questions read left to right inside the Arabic app),
/// while the app's labels around it keep the app's direction.
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selectedAnswerId,
    required this.onAnswerSelected,
  });

  final QuizQuestionModel question;
  final int questionNumber;
  final int totalQuestions;
  final int? selectedAnswerId;
  final ValueChanged<int> onAnswerSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final questionText = QuizTextCleanup.question(question.questionText);
    final answers = QuizTextCleanup.options([
      for (final answer in question.answers) answer.answerText,
    ]);
    final direction = contentDirectionOf(
      '$questionText ${answers.join(' ')}',
      fallback: Directionality.of(context),
    );
    final latin = direction == TextDirection.ltr;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: colors.cardWhite.withValues(alpha: isDark ? 0.9 : 0.72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Chip(
                label: strings.t('السؤال $questionNumber من $totalQuestions'),
                strong: true,
              ),
              const Spacer(),
              if (question.points > 0)
                _Chip(
                  label: strings.isEnglish
                      ? (question.points == 1
                            ? '1 point'
                            : '${question.points} points')
                      : (question.points == 1
                            ? 'علامة واحدة'
                            : question.points == 2
                            ? 'علامتان'
                            : '${question.points} علامات'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Directionality(
            textDirection: direction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  questionText,
                  style: AppTextStyles.titleOf(context).copyWith(
                    fontSize: 20,
                    height: 1.55,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 22),
                for (var i = 0; i < question.answers.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  QuizAnswerOption(
                    letter: QuizTextCleanup.letter(i, latin: latin),
                    answerText: answers[i],
                    isSelected: selectedAnswerId == question.answers[i].id,
                    onTap: () => onAnswerSelected(question.answers[i].id),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.strong = false});

  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: strong
            ? colors.accent.withValues(alpha: 0.16)
            : colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyOf(context).copyWith(
          fontSize: 12.5,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          color: strong ? colors.darkGold : colors.textMuted,
        ),
      ),
    );
  }
}
