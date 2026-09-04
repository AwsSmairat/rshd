import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../subjects/data/models/subject_model.dart';
import '../../../core/l10n/app_strings.dart';

class CourseProgressCard extends StatelessWidget {
  const CourseProgressCard({
    super.key,
    required this.subject,
    required this.onTap,
    this.progress,
    this.width,
  });

  final SubjectModel subject;
  final VoidCallback onTap;
  final double? progress;
  final double? width;

  Color _gradientStart(BuildContext context) {
    switch (subject.category) {
      case 'medicine':
        return const Color(0xFF7F1D1D);
      case 'engineering':
        return const Color(0xFF92400E);
      case 'it':
        return const Color(0xFF1E3A8A);
      default:
        return AppColors.of(context).secondaryNavy;
    }
  }

  Color _gradientEnd(BuildContext context) {
    switch (subject.category) {
      case 'medicine':
        return const Color(0xFF991B1B);
      case 'engineering':
        return AppColors.of(context).darkGold;
      case 'it':
        return AppColors.of(context).primary;
      default:
        return AppColors.of(context).primary;
    }
  }

  String _badgeLabel(BuildContext context) {
    if (AppStrings.of(context).t(subject.categoryLabel).isNotEmpty &&
        AppStrings.of(context).t(subject.categoryLabel) != subject.category) {
      return AppStrings.of(context).t(subject.categoryLabel);
    }
    return subject.title.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final instructorName = subject.instructor?.name;
    final showProgress = progress != null;
    final coverUrl = subject.resolvedCoverImageUrl;

    return LiquidGlassSurface(
      width: width,
      borderRadius: BorderRadius.circular(18),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: coverUrl != null
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _CoverFallback(
                                gradientStart: _gradientStart(context),
                                gradientEnd: _gradientEnd(context),
                              ),
                        )
                      : _CoverFallback(
                          gradientStart: _gradientStart(context),
                          gradientEnd: _gradientEnd(context),
                        ),
                ),
              ),
              if (coverUrl != null)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(AppStrings.of(context).t(_badgeLabel(context)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.of(context).t(subject.title),
                  style: AppTextStyles.subtitleOf(context).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (instructorName != null && instructorName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(AppStrings.of(context).t(instructorName),
                    style: AppTextStyles.bodyOf(context).copyWith(
                      fontSize: 12,
                      color: AppColors.of(context).textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (showProgress) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress!.clamp(0, 1),
                            minHeight: 6,
                            backgroundColor: AppColors.of(
                              context,
                            ).accent.withValues(alpha: 0.18),
                            color: AppColors.of(context).accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(AppStrings.of(context).t('${(progress! * 100).round()}%'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).darkGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({
    required this.gradientStart,
    required this.gradientEnd,
  });

  final Color gradientStart;
  final Color gradientEnd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [gradientStart, gradientEnd],
        ),
      ),
    );
  }
}
