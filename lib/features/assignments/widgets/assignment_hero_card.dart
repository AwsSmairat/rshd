import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/assignment_model.dart';
import 'assignment_icon_helper.dart';
import 'assignment_icon_panel.dart';
import 'submission_status_badge.dart';

class AssignmentHeroCard extends StatelessWidget {
  const AssignmentHeroCard({super.key, required this.assignment});

  final AssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    final icon = AssignmentIconHelper.iconFor(
      title: assignment.title,
      subjectTitle: assignment.subjectTitle,
    );

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(26),
      padding: const EdgeInsets.all(20),
      fillOpacity: 0.38,
      borderOpacity: 0.7,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.04,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: AppTextStyles.titleOf(context).copyWith(
                    fontSize: 20,
                    height: 1.3,
                    color: AppColors.of(context).primary,
                  ),
                ),
                if (assignment.subjectTitle != null &&
                    assignment.subjectTitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    assignment.subjectTitle!,
                    style: AppTextStyles.bodyOf(
                      context,
                    ).copyWith(color: AppColors.of(context).textMuted),
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
    );
  }
}

class AssignmentInfoGrid extends StatelessWidget {
  const AssignmentInfoGrid({super.key, required this.assignment});

  final AssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    final submissionStatus = assignment.isSubmitted
        ? 'تم التسليم'
        : assignment.isOverdue
        ? 'منتهي'
        : 'لم يتم التسليم';

    final stats = [
      _GridItem(
        icon: Icons.menu_book_outlined,
        label: 'المادة',
        value: assignment.subjectTitle ?? '—',
      ),
      _GridItem(
        icon: Icons.school_outlined,
        label: 'الدرس',
        value: assignment.lessonTitle ?? '—',
      ),
      _GridItem(
        icon: Icons.calendar_today_outlined,
        label: 'تاريخ التسليم',
        value: _formatDate(assignment.dueDate),
      ),
      _GridItem(
        icon: Icons.fact_check_outlined,
        label: 'حالة التسليم',
        value: submissionStatus,
        valueColor: assignment.isSubmitted
            ? const Color(0xFF15803D)
            : assignment.isOverdue
            ? const Color(0xFF991B1B)
            : AppColors.of(context).darkGold,
      ),
    ];

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      fillOpacity: 0.38,
      borderOpacity: 0.7,
      blurSigma: 16,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: AppColors.of(context).darkGold,
                ),
                const SizedBox(width: 8),
                Text(
                  'معلومات الواجب',
                  style: AppTextStyles.subtitleOf(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).primary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildCell(
                  context,
                  stats[0],
                  showRight: true,
                  showBottom: true,
                ),
              ),
              Expanded(child: _buildCell(context, stats[1], showBottom: true)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCell(context, stats[2], showRight: true)),
              Expanded(child: _buildCell(context, stats[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    _GridItem item, {
    bool showRight = false,
    bool showBottom = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: showRight
              ? BorderSide(color: Colors.white.withValues(alpha: 0.45))
              : BorderSide.none,
          bottom: showBottom
              ? BorderSide(color: Colors.white.withValues(alpha: 0.45))
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.of(context).accent.withValues(alpha: 0.14),
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: AppColors.of(context).darkGold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: AppTextStyles.bodyOf(
                context,
              ).copyWith(fontSize: 12, color: AppColors.of(context).textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              item.value,
              style: AppTextStyles.bodyOf(context).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: item.valueColor ?? AppColors.of(context).primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd', 'ar').format(parsed.toLocal());
  }
}

class _GridItem {
  const _GridItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}
