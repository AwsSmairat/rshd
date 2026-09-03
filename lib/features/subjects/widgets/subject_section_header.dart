import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SubjectSectionHeader extends StatelessWidget {
  const SubjectSectionHeader({
    super.key,
    required this.title,
    required this.categoryKey,
  });

  final String title;
  final String categoryKey;

  IconData get _icon {
    switch (categoryKey) {
      case 'medicine':
        return Icons.medical_services_outlined;
      case 'it':
        return Icons.terminal_outlined;
      case 'engineering':
        return Icons.architecture_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  Color _iconColor(BuildContext context) {
    switch (categoryKey) {
      case 'medicine':
        return const Color(0xFF0F766E);
      case 'it':
        return const Color(0xFF234E70);
      case 'engineering':
        return AppColors.of(context).darkGold;
      default:
        return AppColors.of(context).primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.of(context).accent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.of(context).accent.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon, size: 18, color: _iconColor(context)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.of(context).primary,
            ),
          ),
        ),
      ],
    );
  }
}
