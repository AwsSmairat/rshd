import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    final tasks = <UpcomingTaskItem>[];

    for (final assignment in assignments.where((item) => !item.isSubmitted)) {
      tasks.add(
        UpcomingTaskItem(
          type: UpcomingTaskType.assignment,
          title: assignment.title,
          subtitle: assignment.subjectTitle ?? 'واجب دراسي',
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
          subtitle: quiz.subjectTitle ?? 'اختبار',
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
    final tasks = _buildTasks(context);

    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: 'المهام القادمة',
            onViewAll: () => context.push(AppRoutes.assignments),
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.of(context).cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                'لا توجد مهام قادمة حالياً',
                style: AppTextStyles.bodyOf(
                  context,
                ).copyWith(color: AppColors.of(context).textMuted),
                textAlign: TextAlign.center,
              ),
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
