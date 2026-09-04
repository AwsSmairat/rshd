import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/data/models/subject_model.dart';
import '../../subjects/widgets/subject_grouping_helper.dart';
import 'department_card.dart';
import 'home_section_header.dart';

class AcademicDepartmentsSection extends StatelessWidget {
  const AcademicDepartmentsSection({super.key, required this.subjects});

  final List<SubjectModel> subjects;

  int _countForCategory(String category) {
    return subjects
        .where(
          (subject) =>
              SubjectGroupingHelper.resolveCategoryKey(subject) == category,
        )
        .length;
  }

  String _subjectCountLabel(BuildContext context, int count) {
    return AppStrings.of(context).subjectCountLabel(count);
  }

  List<DepartmentCard> _buildCards(BuildContext context) {
    final strings = AppStrings.of(context);
    return [
      DepartmentCard(
        title: strings.informationTechnology,
        subtitle: strings.itDepartmentSubtitle,
        countLabel: _subjectCountLabel(context, _countForCategory('it')),
        icon: Icons.code_outlined,
        titleColor: AppColors.of(context).primary,
        badgeColor: AppColors.of(context).primary,
        iconBackground: AppColors.of(context).primary.withValues(alpha: 0.08),
        onTap: () => context.push(AppRoutes.subjectsByCategory('it')),
      ),
      DepartmentCard(
        title: strings.engineering,
        subtitle: strings.engineeringSubtitle,
        countLabel: _subjectCountLabel(
          context,
          _countForCategory('engineering'),
        ),
        icon: Icons.architecture_outlined,
        titleColor: AppColors.of(context).darkGold,
        badgeColor: AppColors.of(context).darkGold,
        iconBackground: AppColors.of(context).accent.withValues(alpha: 0.18),
        onTap: () => context.push(AppRoutes.subjectsByCategory('engineering')),
      ),
      DepartmentCard(
        title: strings.medicine,
        subtitle: strings.medicineSubtitle,
        countLabel: _subjectCountLabel(context, _countForCategory('medicine')),
        icon: Icons.medical_services_outlined,
        titleColor: const Color(0xFF991B1B),
        badgeColor: const Color(0xFF991B1B),
        iconBackground: const Color(0xFF991B1B).withValues(alpha: 0.1),
        onTap: () => context.push(AppRoutes.subjectsByCategory('medicine')),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);
    final cards = _buildCards(context);

    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: AppStrings.of(context).academicDepartments,
            onViewAll: () => context.push(AppRoutes.subjects),
          ),
          const SizedBox(height: 8),
          if (metrics.useDepartmentRow)
            SizedBox(
              height: metrics.isLargeTablet ? 250 : 230,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              ),
            )
          else
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: cards.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(width: 168, child: cards[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}
