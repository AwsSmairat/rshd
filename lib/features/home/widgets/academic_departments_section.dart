import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/data/models/subject_model.dart';
import '../../subjects/widgets/subject_grouping_helper.dart';
import 'specialty_card.dart';
import 'home_section_header.dart';

class AcademicDepartmentsSection extends StatelessWidget {
  const AcademicDepartmentsSection({
    super.key,
    required this.subjects,
    this.showViewAll = true,
  });

  final List<SubjectModel> subjects;

  /// Off on the Subjects tab, where "view all" would point at itself.
  final bool showViewAll;

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

  List<Widget> _buildCards(BuildContext context) {
    final strings = AppStrings.of(context);
    SpecialtyCard card(
      Specialty specialty,
      String key,
      String title,
      String subtitle,
    ) => SpecialtyCard(
      specialty: specialty,
      title: title,
      subtitle: subtitle,
      countLabel: _subjectCountLabel(context, _countForCategory(key)),
      onOpen: () => context.push(AppRoutes.subjectsByCategory(key)),
    );

    return [
      card(
        Specialty.medicine,
        'medicine',
        strings.medicine,
        strings.medicineSubtitle,
      ),
      card(
        Specialty.it,
        'it',
        strings.informationTechnology,
        strings.itDepartmentSubtitle,
      ),
      card(
        Specialty.engineering,
        'engineering',
        strings.engineering,
        strings.engineeringSubtitle,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);
    final cards = _buildCards(context);

    final header = HomeSectionHeader(
      title: AppStrings.of(context).academicDepartments,
      onViewAll: showViewAll ? () => context.go(AppRoutes.subjects) : null,
    );

    if (metrics.useDepartmentRow) {
      return ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 8),
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
            ),
          ],
        ),
      );
    }

    // On phones the carousel runs edge to edge: the first card lines up with
    // the page margin and the rest scroll out to the screen edge instead of
    // being cut off at the margin.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveContent(child: header),
        const SizedBox(height: 8),
        SizedBox(
          height: 246,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              metrics.outerHorizontalInset,
              4,
              metrics.outerHorizontalInset,
              12,
            ),
            itemCount: cards.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(width: 176, child: cards[index]);
            },
          ),
        ),
      ],
    );
  }
}
