import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/data/models/subject_model.dart';
import 'home_section_header.dart';

const _navy = Color(0xFF0B1F3A);

/// "Continue where you left off": the top courses in progress as rows — the
/// course poster, title, instructor, progress and a resume button — the way
/// the large learning platforms lead their home screens.
class ContinueLearningSection extends StatelessWidget {
  const ContinueLearningSection({
    super.key,
    required this.subjects,
    required this.progressFor,
  });

  final List<SubjectModel> subjects;
  final double Function(SubjectModel subject) progressFor;

  static const _maxRows = 3;

  @override
  Widget build(BuildContext context) {
    final shown = subjects.take(_maxRows).toList();

    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: AppStrings.of(context).continueWhereYouLeft,
            onViewAll: subjects.length > _maxRows
                ? () => context.go(AppRoutes.subjects)
                : null,
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty) const _StartLearningCard(),
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            ContinueLearningCard(
              subject: shown[i],
              progressPercent: progressFor(shown[i]),
            ),
          ],
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
  });

  final SubjectModel subject;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final progress = progressPercent.clamp(0, 100).toDouble();
    final instructor = subject.instructor?.name;
    final radius = BorderRadius.circular(20);
    void open() =>
        context.push(AppRoutes.subjectDetails(subject.id), extra: subject);

    // The course cover fills the whole card. A navy wash runs from the text
    // side across, so the title stays readable while the artwork shows on
    // the far side.
    return SizedBox(
      height: 132,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: _navy,
            child: InkWell(
              onTap: open,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Cover(subject: subject),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                        stops: [0.0, 0.55, 1.0],
                        colors: [
                          Color(0xF20B1F3A),
                          Color(0xB30B1F3A),
                          Color(0x330B1F3A),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                strings.t(subject.title),
                                style: AppTextStyles.bodyOf(context).copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (instructor != null &&
                                  instructor.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  strings.t(instructor),
                                  style: AppTextStyles.bodyOf(context).copyWith(
                                    fontSize: 12.5,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 6,
                                  value: progress / 100,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.22,
                                  ),
                                  color: colors.accent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                strings.percentComplete(progress.round()),
                                style: AppTextStyles.bodyOf(context).copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Semantics(
                          button: true,
                          label: strings.continueLearning,
                          excludeSemantics: true,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: _navy,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the course rows when the student has no course yet.
class _StartLearningCard extends StatelessWidget {
  const _StartLearningCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF16345C), _navy],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              color: colors.accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.startLearningTitle,
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.startLearningHint,
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.subjects),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: _navy,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    strings.browseCourses,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.subject});

  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    final url = subject.resolvedCoverImageUrl;
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16345C), _navy],
        ),
      ),
      child: Icon(
        Icons.play_lesson_outlined,
        color: AppColors.of(context).accent.withValues(alpha: 0.8),
      ),
    );
    if (url == null) return fallback;
    return Image(
      image: cachedImage(url),
      fit: BoxFit.cover,
      alignment: const Alignment(0, 0.35),
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
