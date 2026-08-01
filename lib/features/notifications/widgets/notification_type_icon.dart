import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class NotificationTypeIcon extends StatelessWidget {
  const NotificationTypeIcon({
    super.key,
    required this.type,
    this.size = 22,
  });

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = _colors();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.background,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _icon(),
        color: colors.foreground,
        size: size,
      ),
    );
  }

  IconData _icon() {
    switch (type) {
      case 'subject_activated':
        return Icons.school_outlined;
      case 'activation_request':
        return Icons.pending_actions_outlined;
      case 'assignment_created':
      case 'new_assignment':
      case 'assignment_reminder':
        return Icons.assignment_outlined;
      case 'quiz_created':
      case 'new_quiz':
      case 'quiz_available':
        return Icons.quiz_outlined;
      case 'grade_published':
      case 'new_grade':
        return Icons.grade_outlined;
      case 'assignment_submitted':
        return Icons.upload_file_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'student_message':
        return Icons.support_agent_outlined;
      case 'instructor_reply':
        return Icons.reply_outlined;
      case 'custom':
      default:
        return Icons.notifications_outlined;
    }
  }

  _TypeColors _colors() {
    switch (type) {
      case 'subject_activated':
        return const _TypeColors(
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF166534),
        );
      case 'activation_request':
        return const _TypeColors(
          background: Color(0xFFFEE2E2),
          foreground: Color(0xFF991B1B),
        );
      case 'assignment_created':
      case 'new_assignment':
      case 'assignment_reminder':
        return _TypeColors(
          background: AppColors.accent.withValues(alpha: 0.2),
          foreground: AppColors.darkGold,
        );
      case 'quiz_created':
      case 'new_quiz':
      case 'quiz_available':
        return const _TypeColors(
          background: Color(0xFFE8F0F8),
          foreground: Color(0xFF234E70),
        );
      case 'grade_published':
      case 'new_grade':
        return _TypeColors(
          background: AppColors.primary.withValues(alpha: 0.1),
          foreground: AppColors.primary,
        );
      case 'assignment_submitted':
        return const _TypeColors(
          background: Color(0xFFFEF3C7),
          foreground: Color(0xFF92400E),
        );
      case 'instructor_reply':
        return _TypeColors(
          background: AppColors.accent.withValues(alpha: 0.22),
          foreground: AppColors.darkGold,
        );
      case 'student_message':
        return const _TypeColors(
          background: Color(0xFFE8F0F8),
          foreground: Color(0xFF234E70),
        );
      case 'announcement':
      case 'custom':
      default:
        return _TypeColors(
          background: AppColors.textMuted.withValues(alpha: 0.12),
          foreground: AppColors.secondary,
        );
    }
  }
}

class _TypeColors {
  const _TypeColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
