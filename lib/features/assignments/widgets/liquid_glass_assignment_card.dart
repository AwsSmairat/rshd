import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/assignment_model.dart';
import 'assignment_icon_helper.dart';
import 'assignment_icon_panel.dart';
import 'submission_status_badge.dart';

class LiquidGlassAssignmentCard extends StatelessWidget {
  const LiquidGlassAssignmentCard({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  final AssignmentModel assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = AssignmentIconHelper.iconFor(
      title: assignment.title,
      subjectTitle: assignment.subjectTitle,
    );

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      fillOpacity: 0.35,
      borderOpacity: 0.65,
      blurSigma: 16,
      tintColor: AppColors.accent,
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
                      child: Text(
                        assignment.title,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 17,
                          height: 1.3,
                          color: AppColors.primary,
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
                            AppColors.accent.withValues(alpha: 0.45),
                            AppColors.darkGold,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (assignment.subjectTitle != null &&
                    assignment.subjectTitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    assignment.subjectTitle!,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (assignment.dueDate != null &&
                    assignment.dueDate!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.darkGold,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'تاريخ التسليم: ${_formatDate(assignment.dueDate!)}',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SubmissionStatusBadge(assignment: assignment),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AssignmentIconPanel(icon: icon),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.primary.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd', 'ar').format(parsed.toLocal());
  }
}
