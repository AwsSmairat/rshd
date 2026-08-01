import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/data/models/subject_model.dart';
import 'home_section_header.dart';

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    super.key,
    required this.subject,
    this.progressPercent = 0,
  });

  final SubjectModel subject;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    final progress = progressPercent.clamp(0, 100);
    final instructorName = subject.instructor?.name;

    return ResponsiveContent(
      child: LiquidGlassSurface(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        fillOpacity: 0.26,
        borderOpacity: 0.55,
        tintColor: AppColors.primary,
        tintOpacity: 0.07,
        blurSigma: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeSectionHeader(title: 'تابع من حيث توقفت'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SubjectThumb(subject: subject),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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
                onPressed: () => context.push(AppRoutes.subjectDetails(subject.id)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('متابعة التعلم'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectThumb extends StatelessWidget {
  const _SubjectThumb({required this.subject});

  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    final url = subject.resolvedCoverImageUrl;

    return Container(
      width: 72,
      height: 72,
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
    return const Icon(
      Icons.play_lesson_outlined,
      color: AppColors.secondary,
      size: 32,
    );
  }
}
