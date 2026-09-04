import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/subject_model.dart';
import 'subject_grouping_helper.dart';
import '../../../core/l10n/app_strings.dart';

class SubjectCategoryBadge extends StatelessWidget {
  const SubjectCategoryBadge({super.key, required this.subject});

  final SubjectModel subject;

  Color _textColor(BuildContext context) {
    switch (SubjectGroupingHelper.resolveCategoryKey(subject)) {
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
    final label =
        AppStrings.of(context).t(subject.categoryLabel).isNotEmpty &&
            AppStrings.of(context).t(subject.categoryLabel) != subject.category
        ? AppStrings.of(context).t(subject.categoryLabel)
        : _fallbackLabel(context);

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
                AppColors.of(context).accent.withValues(alpha: 0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
          ),
          child: Text(AppStrings.of(context).t(label),
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textColor(context),
            ),
          ),
        ),
      ),
    );
  }

  String _fallbackLabel(BuildContext context) {
    switch (SubjectGroupingHelper.resolveCategoryKey(subject)) {
      case 'medicine':
        return AppStrings.of(context).t('طب');
      case 'it':
        return AppStrings.of(context).t('تقنية');
      case 'engineering':
        return AppStrings.of(context).t('هندسة');
      default:
        return AppStrings.of(context).t('عام');
    }
  }
}
