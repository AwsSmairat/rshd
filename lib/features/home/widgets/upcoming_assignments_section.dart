import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../assignments/data/models/assignment_model.dart';
import '../../quizzes/data/models/quiz_model.dart';
import '../../../core/widgets/responsive_content.dart';
import 'home_section_header.dart';
import 'upcoming_task_card.dart';

class UpcomingAssignmentsSection extends StatelessWidget {
  const UpcomingAssignmentsSection({
    super.key,
    required this.assignments,
    required this.quizzes,
  });

  final List<AssignmentModel> assignments;
  final List<QuizModel> quizzes;

  List<UpcomingTaskItem> _buildTasks(BuildContext context) {
    final strings = AppStrings.of(context);
    final tasks = <UpcomingTaskItem>[];

    for (final assignment in assignments.where((item) => !item.isSubmitted)) {
      tasks.add(
        UpcomingTaskItem(
          type: UpcomingTaskType.assignment,
          title: assignment.title,
          subtitle: assignment.subjectTitle ?? strings.studyAssignment,
          date: DateTime.tryParse(assignment.dueDate ?? ''),
          onTap: () => context.push(AppRoutes.assignmentDetails(assignment.id)),
        ),
      );
    }

    for (final quiz in quizzes.where(
      (item) => item.isActive && !item.isCompleted,
    )) {
      tasks.add(
        UpcomingTaskItem(
          type: UpcomingTaskType.quiz,
          title: quiz.title,
          subtitle: quiz.subjectTitle ?? strings.quiz,
          date: DateTime.tryParse(quiz.createdAt ?? ''),
          onTap: () => context.push(AppRoutes.quizDetails(quiz.id)),
        ),
      );
    }

    tasks.sort((a, b) {
      if (a.date == null && b.date == null) {
        return 0;
      }
      if (a.date == null) {
        return 1;
      }
      if (b.date == null) {
        return -1;
      }
      return a.date!.compareTo(b.date!);
    });

    return tasks.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tasks = _buildTasks(context);

    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: strings.upcomingTasks,
            onViewAll: tasks.isEmpty
                ? null
                : () => context.go(AppRoutes.assignments),
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            _EmptyTasks(
              title: AppStrings.of(context).t(strings.noUpcomingTasks),
              hint: strings.upcomingEmptyHint,
            )
          else
            ...List.generate(
              tasks.length,
              (index) => UpcomingTaskCard(
                task: tasks[index],
                isLast: index == tasks.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

/// Nothing due: a quiet card with an icon and one line of guidance.
class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF15803D).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF15803D),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hint,
                  style: AppTextStyles.bodyOf(
                    context,
                  ).copyWith(fontSize: 12.5, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
