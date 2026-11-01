import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/app_strings.dart';

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
        // Same look as the home section titles: a soft tile, no accent bar.
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _iconColor(context).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(_icon, size: 19, color: _iconColor(context)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppStrings.of(context).t(title),
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.of(context).text,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
