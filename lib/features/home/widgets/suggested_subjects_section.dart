import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/cached_image.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../subjects/data/models/subject_model.dart';
import 'home_section_header.dart';

/// Catalogue courses the student is not enrolled in yet.
class SuggestedSubjectsSection extends StatelessWidget {
  const SuggestedSubjectsSection({super.key, required this.subjects});

  final List<SubjectModel> subjects;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) return const SizedBox.shrink();
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: strings.suggestedForYou,
          onViewAll: () => context.go(AppRoutes.subjects),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 238,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _SuggestedCard(subject: subjects[index]),
          ),
        ),
      ],
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard({required this.subject});

  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final url = subject.resolvedCoverImageUrl;
    final instructor = subject.instructor?.name;
    final radius = BorderRadius.circular(18);

    return SizedBox(
      width: 230,
      child: Material(
        color: colors.cardWhite,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.subjectDetails(subject.id),
            extra: subject,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: colors.primary.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 16:9 like course cards on the big platforms; the poster's
                // title area sits at its top, so anchor the crop there.
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: url == null
                      ? DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF16345C), Color(0xFF0B1F3A)],
                            ),
                          ),
                          child: Icon(
                            Icons.auto_stories_outlined,
                            color: colors.accent,
                            size: 34,
                          ),
                        )
                      : Image(
                          image: cachedImage(url),
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.75),
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: Color(0xFF0B1F3A)),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.darkGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          strings.departmentTitle(subject.category),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.darkGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.t(subject.title),
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: colors.text,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (instructor != null && instructor.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          strings.t(instructor),
                          style: AppTextStyles.bodyOf(
                            context,
                          ).copyWith(fontSize: 12, color: colors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
