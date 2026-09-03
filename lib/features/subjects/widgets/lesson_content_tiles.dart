import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../assignments/data/models/assignment_model.dart';
import '../../assignments/widgets/submission_status_badge.dart';
import '../../quizzes/data/models/quiz_model.dart';
import '../../quizzes/widgets/quiz_status_badge.dart';

class LessonAssignmentTile extends StatelessWidget {
  const LessonAssignmentTile({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  final AssignmentModel assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.of(
              context,
            ).accent.withValues(alpha: 0.16),
            child: Icon(
              Icons.assignment_outlined,
              color: AppColors.of(context).darkGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: AppTextStyles.bodyOf(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                if (assignment.dueDate != null &&
                    assignment.dueDate!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'موعد التسليم: ${_formatDate(assignment.dueDate!)}',
                    style: AppTextStyles.bodyOf(context).copyWith(
                      color: AppColors.of(context).textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                SubmissionStatusBadge(assignment: assignment),
              ],
            ),
          ),
          Icon(
            Icons.chevron_left_rounded,
            color: AppColors.of(context).primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
  }
}

class LessonQuizTile extends StatelessWidget {
  const LessonQuizTile({super.key, required this.quiz, required this.onTap});

  final QuizModel quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = quiz.durationMinutes;
    final questions = quiz.questionsCount;

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.of(
              context,
            ).primary.withValues(alpha: 0.12),
            child: Icon(
              Icons.quiz_outlined,
              color: AppColors.of(context).primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: AppTextStyles.bodyOf(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                if (duration != null || questions != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (duration != null) '$duration دقيقة',
                      if (questions != null) '$questions سؤال',
                    ].join(' · '),
                    style: AppTextStyles.bodyOf(context).copyWith(
                      color: AppColors.of(context).textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                QuizStatusBadge(quiz: quiz),
              ],
            ),
          ),
          Icon(
            Icons.chevron_left_rounded,
            color: AppColors.of(context).primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
