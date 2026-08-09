import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/assignment_model.dart';

class SubmissionStatusBadge extends StatelessWidget {
  const SubmissionStatusBadge({super.key, required this.assignment});

  final AssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.foreground),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: style.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusStyle _resolveStyle() {
    if (assignment.isSubmitted) {
      return const _StatusStyle(
        label: 'تم التسليم',
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF15803D),
        icon: Icons.check_circle_outline,
      );
    }
    if (assignment.isOverdue) {
      return const _StatusStyle(
        label: 'منتهي',
        background: Color(0xFFFEE2E2),
        foreground: Color(0xFF991B1B),
        icon: Icons.warning_rounded,
      );
    }
    return const _StatusStyle(
      label: 'لم يتم التسليم',
      background: Color(0xFFF8EED6),
      foreground: AppColors.darkGold,
      icon: Icons.hourglass_empty_rounded,
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
}
