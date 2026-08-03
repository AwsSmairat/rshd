import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/data/models/subject_model.dart';
import 'home_section_header.dart';

class ContinueLearningSection extends StatelessWidget {
  const ContinueLearningSection({
    super.key,
    required this.subjects,
    required this.progressFor,
  });

  final List<SubjectModel> subjects;
  final double Function(SubjectModel subject) progressFor;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return const SizedBox.shrink();
    }

    final metrics = AppLayoutMetrics.of(context);
    final cardWidth = metrics.isTablet ? 340.0 : 300.0;

    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeSectionHeader(title: 'تابع من حيث توقفت'),
          const SizedBox(height: 12),
          if (subjects.length == 1)
            ContinueLearningCard(
              subject: subjects.first,
              progressPercent: progressFor(subjects.first),
            )
          else
            SizedBox(
              height: 228,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: subjects.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return SizedBox(
                    width: cardWidth,
                    child: ContinueLearningCard(
                      subject: subject,
                      progressPercent: progressFor(subject),
                      compact: true,
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

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    super.key,
    required this.subject,
    this.progressPercent = 0,
    this.compact = false,
  });

  final SubjectModel subject;
  final double progressPercent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = progressPercent.clamp(0, 100);
    final instructorName = subject.instructor?.name;

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.all(compact ? 14 : 16),
      fillOpacity: 0.26,
      borderOpacity: 0.55,
      tintColor: AppColors.primary,
      tintOpacity: 0.07,
      blurSigma: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubjectThumb(
                subject: subject,
                size: compact ? 64 : 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 14 : 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (instructorName != null && instructorName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        instructorName,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress / 100,
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${progress.round()}% مكتمل',
            style: AppTextStyles.body.copyWith(
              fontSize: 11,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              onPressed: () => context.push(
                AppRoutes.subjectDetails(subject.id),
                extra: subject,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 18,
                  vertical: compact ? 8 : 10,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'متابعة التعلم',
                style: TextStyle(fontSize: compact ? 13 : 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectThumb extends StatelessWidget {
  const _SubjectThumb({
    required this.subject,
    this.size = 72,
  });

  final SubjectModel subject;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = subject.resolvedCoverImageUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.35),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Icon(
      Icons.play_lesson_outlined,
      color: AppColors.secondary,
      size: size * 0.44,
    );
  }
}
