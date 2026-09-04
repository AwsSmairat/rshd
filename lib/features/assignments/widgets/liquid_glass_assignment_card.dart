import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/assignment_model.dart';
import 'assignment_icon_helper.dart';
import 'assignment_icon_panel.dart';
import 'submission_status_badge.dart';
import '../../../core/l10n/app_strings.dart';

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
                      child: Text(AppStrings.of(context).t(assignment.title),
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
                if (assignment.subjectTitle != null &&
                    assignment.subjectTitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(AppStrings.of(context).t(assignment.subjectTitle!),
                    style: AppTextStyles.bodyOf(context).copyWith(
                      fontSize: 13,
                      color: AppColors.of(context).textMuted,
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
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.of(context).darkGold,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(AppStrings.of(context).t('تاريخ التسليم: ${_formatDate(context, assignment.dueDate!)}'),
                          style: AppTextStyles.bodyOf(context).copyWith(
                            fontSize: 12,
                            color: AppColors.of(context).textMuted,
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
            color: AppColors.of(context).primary.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd', AppStrings.of(context).dateLocale).format(parsed.toLocal());
  }
}
