import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class GradeTypeBadge extends StatelessWidget {
  const GradeTypeBadge({super.key, required this.sourceType});

  final String sourceType;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(),
        style: AppTextStyles.bodyOf(context).copyWith(
          fontSize: 12,
          color: colors.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _label() {
    switch (sourceType) {
      case 'assignment':
        return 'واجب';
      case 'quiz':
        return 'اختبار';
      case 'manual':
        return 'درجة يدوية';
      default:
        return sourceType;
    }
  }

  _BadgeColors _colors(BuildContext context) {
    switch (sourceType) {
      case 'quiz':
        return const _BadgeColors(
          background: Color(0xFFE8F0F8),
          foreground: Color(0xFF234E70),
        );
      case 'assignment':
        return _BadgeColors(
          background: AppColors.of(context).accent.withValues(alpha: 0.2),
          foreground: AppColors.of(context).darkGold,
        );
      case 'manual':
      default:
        return _BadgeColors(
          background: AppColors.of(context).primary.withValues(alpha: 0.08),
          foreground: AppColors.of(context).primary,
        );
    }
  }
}

class _BadgeColors {
  const _BadgeColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
