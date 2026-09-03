import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/data/models/subject_model.dart';
import 'course_progress_card.dart';
import 'home_section_header.dart';

class RecentSubjectsSection extends StatelessWidget {
  const RecentSubjectsSection({super.key, required this.subjects});

  final List<SubjectModel> subjects;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);

    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: 'موادي الحالية',
            onViewAll: () => context.push(AppRoutes.subjects),
          ),
          const SizedBox(height: 8),
          if (subjects.isEmpty)
            LiquidGlassSurface(
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(18),
              child: Text(
                'لا توجد مواد مفعلة حالياً',
                style: AppTextStyles.bodyOf(
                  context,
                ).copyWith(color: AppColors.of(context).textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else if (metrics.useSubjectGrid)
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = metrics.subjectGridColumns;
                const spacing = 12.0;
                final tileWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final subject in subjects)
                      SizedBox(
                        width: tileWidth,
                        child: CourseProgressCard(
                          subject: subject,
                          progress: subject.isEnrollmentActive
                              ? subject.progressPercent! / 100
                              : null,
                          onTap: () => context.push(
                            AppRoutes.subjectDetails(subject.id),
                            extra: subject,
                          ),
                        ),
                      ),
                  ],
                );
              },
            )
          else
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: subjects.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return CourseProgressCard(
                    subject: subject,
                    width: 240,
                    progress: subject.isEnrollmentActive
                        ? subject.progressPercent! / 100
                        : null,
                    onTap: () => context.push(
                      AppRoutes.subjectDetails(subject.id),
                      extra: subject,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
