import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/data/models/subject_model.dart';
import '../../subjects/widgets/subject_grouping_helper.dart';
import 'department_card.dart';
import 'home_section_header.dart';

class AcademicDepartmentsSection extends StatelessWidget {
  const AcademicDepartmentsSection({
    super.key,
    required this.subjects,
  });

  final List<SubjectModel> subjects;

  int _countForCategory(String category) {
    return subjects
        .where(
          (subject) =>
              SubjectGroupingHelper.resolveCategoryKey(subject) == category,
        )
        .length;
  }

  String _subjectCountLabel(int count) {
    if (count == 0) {
      return '0 مواد';
    }
    if (count == 1) {
      return '1 مادة';
    }
    if (count == 2) {
      return '2 مادتان';
    }
    if (count >= 3 && count <= 10) {
      return '$count مواد';
    }
    return '$count مادة';
  }

  List<DepartmentCard> _buildCards(BuildContext context) {
    return [
      DepartmentCard(
        title: 'تكنولوجيا المعلومات',
        subtitle: 'برمج، ابتكر، وكن جزءاً من مستقبل التقنية',
        countLabel: _subjectCountLabel(_countForCategory('it')),
        icon: Icons.code_outlined,
        titleColor: AppColors.primary,
        badgeColor: AppColors.primary,
        iconBackground: AppColors.primary.withValues(alpha: 0.08),
        onTap: () => context.push(AppRoutes.subjectsByCategory('it')),
      ),
      DepartmentCard(
        title: 'الهندسة',
        subtitle: 'تعلم وطور مهاراتك الهندسية',
        countLabel: _subjectCountLabel(_countForCategory('engineering')),
        icon: Icons.architecture_outlined,
        titleColor: AppColors.darkGold,
        badgeColor: AppColors.darkGold,
        iconBackground: AppColors.accent.withValues(alpha: 0.18),
        onTap: () => context.push(AppRoutes.subjectsByCategory('engineering')),
      ),
      DepartmentCard(
        title: 'الطب',
        subtitle: 'كل ما تحتاجه لدراستك في مجال الطب',
        countLabel: _subjectCountLabel(_countForCategory('medicine')),
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
            title: 'الأقسام الأكاديمية',
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
                  return SizedBox(
                    width: 168,
                    child: cards[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
