import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';

enum UpcomingTaskType { assignment, quiz, lecture }

class UpcomingTaskItem {
  const UpcomingTaskItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.date,
  });

  final UpcomingTaskType type;
  final String title;
  final String subtitle;
  final DateTime? date;
  final VoidCallback onTap;
}

class UpcomingTaskCard extends StatelessWidget {
  const UpcomingTaskCard({super.key, required this.task, required this.isLast});

  final UpcomingTaskItem task;
  final bool isLast;

  Color _dotColor(BuildContext context) {
    switch (task.type) {
      case UpcomingTaskType.assignment:
        return AppColors.of(context).darkGold;
      case UpcomingTaskType.quiz:
        return AppColors.of(context).primary;
      case UpcomingTaskType.lecture:
        return const Color(0xFF2563EB);
    }
  }

  IconData get _icon {
    switch (task.type) {
      case UpcomingTaskType.assignment:
        return Icons.assignment_outlined;
      case UpcomingTaskType.quiz:
        return Icons.quiz_outlined;
      case UpcomingTaskType.lecture:
        return Icons.play_circle_outline;
    }
  }

  String _dayLabel() {
    final date = task.date;
    if (date == null) {
      return '--';
    }
    return '${date.day}';
  }

  String _monthLabel(BuildContext context) {
    final date = task.date;
    if (date == null) {
      return '';
    }
    return AppStrings.of(context).monthName(date.month);
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                SizedBox(
                  width: 48,
                  child: LiquidGlassSurface(
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text(AppStrings.of(context).t(_dayLabel()),
                          style: AppTextStyles.titleOf(context).copyWith(
                            fontSize: 18,
                            color: AppColors.of(context).primary,
                          ),
                        ),
                        Text(AppStrings.of(context).t(_monthLabel(context)),
                          style: AppTextStyles.bodyOf(context).copyWith(
                            fontSize: 10,
                            color: AppColors.of(context).textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AppColors.of(
                        context,
                      ).accent.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: LiquidGlassSurface(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(14),
                onTap: task.onTap,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _dotColor(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.of(context).t(task.title),
                            style: AppTextStyles.subtitleOf(context).copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.of(context).text,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(AppStrings.of(context).t(task.subtitle),
                            style: AppTextStyles.bodyOf(context).copyWith(
                              fontSize: 12,
                              color: AppColors.of(context).textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(
                        _icon,
                        color: AppColors.of(context).primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
