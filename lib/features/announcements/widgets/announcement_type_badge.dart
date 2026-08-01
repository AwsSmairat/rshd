import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AnnouncementTypeBadge extends StatelessWidget {
  const AnnouncementTypeBadge({
    super.key,
    required this.type,
  });

  final String type;

  Color get _backgroundColor {
    switch (type) {
      case 'important':
        return AppColors.error.withValues(alpha: 0.1);
      case 'subject':
        return AppColors.secondary.withValues(alpha: 0.1);
      default:
        return AppColors.accent.withValues(alpha: 0.16);
    }
  }

  Color get _textColor {
    switch (type) {
      case 'important':
        return AppColors.error;
      case 'subject':
        return AppColors.secondary;
      default:
        return AppColors.primary;
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
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _textColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        _label,
        style: AppTextStyles.body.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _textColor,
        ),
      ),
    );
  }
}

class AnnouncementTypeIcon extends StatelessWidget {
  const AnnouncementTypeIcon({
    super.key,
    required this.type,
    this.size = 22,
  });

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

  Color get _color {
    switch (type) {
      case 'important':
        return AppColors.error;
      case 'subject':
        return AppColors.secondary;
      default:
        return AppColors.darkGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 18,
      height: size + 18,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, color: _color, size: size),
    );
  }
}
