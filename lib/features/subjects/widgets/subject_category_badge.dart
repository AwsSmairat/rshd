import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/subject_model.dart';
import 'subject_grouping_helper.dart';

class SubjectCategoryBadge extends StatelessWidget {
  const SubjectCategoryBadge({
    super.key,
    required this.subject,
  });

  final SubjectModel subject;

  Color get _textColor {
    switch (SubjectGroupingHelper.resolveCategoryKey(subject)) {
      case 'medicine':
        return const Color(0xFF0F766E);
      case 'it':
        return const Color(0xFF234E70);
      case 'engineering':
        return AppColors.darkGold;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = subject.categoryLabel.isNotEmpty &&
            subject.categoryLabel != subject.category
        ? subject.categoryLabel
        : _fallbackLabel();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.48),
                AppColors.accent.withValues(alpha: 0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.52),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
        ),
      ),
    );
  }

  String _fallbackLabel() {
    switch (SubjectGroupingHelper.resolveCategoryKey(subject)) {
      case 'medicine':
        return 'طب';
      case 'it':
        return 'تقنية';
      case 'engineering':
        return 'هندسة';
      default:
        return 'عام';
    }
  }
}
