import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/widgets/responsive_content.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(18),
      padding: EdgeInsets.all(metrics.isTablet ? 18 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: metrics.isTablet ? 42 : 36,
            height: metrics.isTablet ? 42 : 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.of(context).primary,
              size: metrics.isTablet ? 20 : 18,
            ),
          ),
          const Spacer(),
          Text(AppStrings.of(context).t(value),
            style: AppTextStyles.titleOf(context).copyWith(
              fontSize: metrics.isTablet ? 28 : 24,
              color: AppColors.of(context).text,
            ),
          ),
          Container(
            width: 28,
            height: 2,
            margin: const EdgeInsets.only(top: 5, bottom: 5),
            decoration: BoxDecoration(
              color: AppColors.of(context).accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Text(AppStrings.of(context).t(label),
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: metrics.isTablet ? 12 : 11,
              height: 1.3,
              color: AppColors.of(context).textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class DashboardSummaryGrid extends StatelessWidget {
  const DashboardSummaryGrid({
    super.key,
    required this.subjectsCount,
    required this.unsubmittedAssignmentsCount,
    required this.availableQuizzesCount,
  });

  final int subjectsCount;
  final int unsubmittedAssignmentsCount;
  final int availableQuizzesCount;

  static const _cardHeight = 156.0;
  static const _cardWidth = 148.0;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);
    final strings = AppStrings.of(context);
    final cards = [
      DashboardSummaryCard(
        icon: Icons.menu_book_outlined,
        label: strings.activatedCourses,
        value: '$subjectsCount',
      ),
      DashboardSummaryCard(
        icon: Icons.assignment_outlined,
        label: strings.unsubmittedAssignments,
        value: '$unsubmittedAssignmentsCount',
      ),
      DashboardSummaryCard(
        icon: Icons.quiz_outlined,
        label: strings.availableQuizzes,
        value: '$availableQuizzesCount',
      ),
    ];

    if (metrics.useDashboardSummaryRow) {
      return ResponsiveContent(
        child: Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(
                child: SizedBox(height: _cardHeight, child: cards[i]),
              ),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      );
    }

    return ResponsiveContent(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              SizedBox(width: _cardWidth, height: _cardHeight, child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}
