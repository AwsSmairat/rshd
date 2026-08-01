import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/assignment_model.dart';
import 'assignment_icon_helper.dart';
import 'assignment_icon_panel.dart';
import 'submission_status_badge.dart';

class AssignmentSubmitInfoCard extends StatelessWidget {
  const AssignmentSubmitInfoCard({
    super.key,
    required this.assignment,
  });

  final AssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    final icon = AssignmentIconHelper.iconFor(
      title: assignment.title,
      subjectTitle: assignment.subjectTitle,
    );

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      fillOpacity: 0.38,
      borderOpacity: 0.7,
      blurSigma: 16,
      tintColor: AppColors.accent,
      tintOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.darkGold),
              const SizedBox(width: 8),
              Text(
                'معلومات الواجب',
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    if (assignment.subjectTitle != null &&
                        assignment.subjectTitle!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        assignment.subjectTitle!,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (assignment.dueDate != null &&
                        assignment.dueDate!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'تاريخ التسليم: ${_formatDate(assignment.dueDate!)}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SubmissionStatusBadge(assignment: assignment),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AssignmentIconPanel(icon: icon),
            ],
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
