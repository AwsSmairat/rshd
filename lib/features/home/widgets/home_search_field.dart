import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/cached_image.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../subjects/data/models/subject_model.dart';

/// Looks like a field; tapping it opens a search over every course the app
/// already knows about (enrolled and catalogue), by title or instructor.
class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key, required this.subjects});

  final List<SubjectModel> subjects;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);

    return Semantics(
      button: true,
      label: strings.homeSearchHint,
      excludeSemantics: true,
      child: Material(
        color: colors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showSearch<void>(
            context: context,
            delegate: SubjectSearchDelegate(
              subjects: subjects,
              hint: strings.homeSearchHint,
              noResults: strings.searchNoResults,
            ),
          ),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.primary.withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: colors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.homeSearchHint,
                    style: AppTextStyles.bodyOf(
                      context,
                    ).copyWith(fontSize: 14, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class SubjectSearchDelegate extends SearchDelegate<void> {
  SubjectSearchDelegate({
    required List<SubjectModel> subjects,
    required String hint,
    required this.noResults,
  }) : _subjects = _dedupe(subjects),
       super(searchFieldLabel: hint);

  final List<SubjectModel> _subjects;
  final String noResults;

  /// Enrolled courses come first in the source list, so they win duplicates.
  static List<SubjectModel> _dedupe(List<SubjectModel> subjects) {
    final seen = <int>{};
    return [
      for (final subject in subjects)
        if (seen.add(subject.id)) subject,
    ];
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: colors.background,
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: colors.background,
        foregroundColor: colors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 15),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, null));

  List<SubjectModel> _matches() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _subjects;
    return _subjects.where((subject) {
      return subject.title.toLowerCase().contains(q) ||
          (subject.instructor?.name.toLowerCase().contains(q) ?? false) ||
          subject.categoryLabel.contains(q);
    }).toList();
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final colors = AppColors.of(context);
    final matches = _matches();
    if (matches.isEmpty) {
      return Center(
        child: Text(
          noResults,
          style: AppTextStyles.bodyOf(
            context,
          ).copyWith(color: colors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final subject = matches[index];
        return _SearchResultTile(
          subject: subject,
          onTap: () {
            close(context, null);
            context.push(AppRoutes.subjectDetails(subject.id), extra: subject);
          },
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.subject, required this.onTap});

  final SubjectModel subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final url = subject.resolvedCoverImageUrl;
    final instructor = subject.instructor?.name;

    return Material(
      color: colors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: url == null
                      ? ColoredBox(
                          color: colors.primary,
                          child: Icon(
                            Icons.auto_stories_outlined,
                            color: colors.accent,
                          ),
                        )
                      : Image(
                          image: cachedImage(url),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: colors.primary),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      style: AppTextStyles.bodyOf(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (instructor != null && instructor.isNotEmpty)
                      Text(
                        instructor,
                        style: AppTextStyles.bodyOf(
                          context,
                        ).copyWith(fontSize: 12, color: colors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
