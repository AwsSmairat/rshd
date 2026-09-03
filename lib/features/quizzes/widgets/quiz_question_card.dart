import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'quiz_answer_option.dart';
import '../data/models/quiz_question_model.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'السؤال $questionNumber من $totalQuestions',
          style: AppTextStyles.bodyOf(
            context,
          ).copyWith(color: AppColors.of(context).textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Text(
          question.questionText,
          style: AppTextStyles.titleOf(context).copyWith(fontSize: 18),
        ),
        const SizedBox(height: 20),
        ...question.answers.map(
          (answer) => QuizAnswerOption(
            answerText: answer.answerText,
            isSelected: selectedAnswerId == answer.id,
            onTap: () => onAnswerSelected(answer.id),
          ),
        ),
      ],
    );
  }
}
