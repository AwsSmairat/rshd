import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/app_strings.dart';

class AnnouncementTypeBadge extends StatelessWidget {
  const AnnouncementTypeBadge({super.key, required this.type});

  final String type;

  Color _backgroundColor(BuildContext context) {
    switch (type) {
      case 'important':
        return AppColors.of(context).error.withValues(alpha: 0.1);
      case 'subject':
        return AppColors.of(context).secondary.withValues(alpha: 0.1);
      default:
        return AppColors.of(context).accent.withValues(alpha: 0.16);
    }
  }

  Color _textColor(BuildContext context) {
    switch (type) {
      case 'important':
        return AppColors.of(context).error;
      case 'subject':
        return AppColors.of(context).secondary;
      default:
        return AppColors.of(context).primary;
    }
  }

  String get _label {
    switch (type) {
      case 'general':
        return 'إعلان عام';
      case 'subject':
        return 'إعلان مادة';
      case 'important':
        return 'مهم';
      default:
        return 'إعلان';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textColor(context).withValues(alpha: 0.2)),
      ),
      child: Text(AppStrings.of(context).t(_label),
        style: AppTextStyles.bodyOf(context).copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _textColor(context),
        ),
      ),
    );
  }
}

class AnnouncementTypeIcon extends StatelessWidget {
  const AnnouncementTypeIcon({super.key, required this.type, this.size = 22});

  final String type;
  final double size;

  IconData get _icon {
    switch (type) {
      case 'important':
        return Icons.priority_high_rounded;
      case 'subject':
        return Icons.menu_book_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  Color _color(BuildContext context) {
    switch (type) {
      case 'important':
        return AppColors.of(context).error;
      case 'subject':
        return AppColors.of(context).secondary;
      default:
        return AppColors.of(context).darkGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 18,
      height: size + 18,
      decoration: BoxDecoration(
        color: _color(context).withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, color: _color(context), size: size),
    );
  }
}
