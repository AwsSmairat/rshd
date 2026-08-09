import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../grades/data/models/grade_model.dart';
import '../../grades/widgets/grade_card.dart';
import 'home_section_header.dart';

class GradesSummarySection extends StatelessWidget {
  const GradesSummarySection({
    super.key,
    required this.grades,
    required this.averageGrade,
    required this.highestGrade,
  });

  final List<GradeModel> grades;
  final double? averageGrade;
  final double? highestGrade;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: 'ملخص الدرجات',
            onViewAll: () => context.push(AppRoutes.grades),
          ),
          const SizedBox(height: 14),
          if (grades.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                'لا توجد درجات حالياً',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: 'المتوسط',
                      value: averageGrade != null
                          ? '${averageGrade!.toStringAsFixed(1)}%'
                          : '—',
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: 'الأعلى',
                      value: highestGrade != null
                          ? '${highestGrade!.toStringAsFixed(1)}%'
                          : '—',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...grades.map(
              (grade) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GradeCard(
                  grade: grade,
                  onTap: () => context.push(AppRoutes.gradeDetails(grade.id)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title.copyWith(
            fontSize: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
