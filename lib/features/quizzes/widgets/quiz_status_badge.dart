import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/quiz_model.dart';

class QuizStatusBadge extends StatelessWidget {
  const QuizStatusBadge({super.key, required this.quiz});

  final QuizModel quiz;

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(context);

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
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: 12,
              color: style.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusStyle _resolveStyle(BuildContext context) {
    if (quiz.isCompleted) {
      return const _StatusStyle(
        label: 'تم الحل',
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF15803D),
        icon: Icons.check_circle_outline,
      );
    }
    if (!quiz.isActive) {
      return _StatusStyle(
        label: 'غير متاح',
        background: Color(0xFFF3F4F6),
        foreground: AppColors.of(context).textMuted,
        icon: Icons.lock_outline,
      );
    }
    return _StatusStyle(
      label: 'متاح',
      background: Color(0xFFF8EED6),
      foreground: AppColors.of(context).darkGold,
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
