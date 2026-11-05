import 'package:flutter/material.dart';

import '../../../core/widgets/skeleton.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/l10n/app_strings.dart';

/// Courses empty state; see [AppEmptyState].
class SubjectsEmptyState extends StatelessWidget {
  const SubjectsEmptyState({
    super.key,
    this.message = 'لا توجد مواد مفعلة حالياً',
    this.subtitle = 'سيتم عرض المواد هنا بعد تفعيلها من الإدارة',
    this.icon = Icons.auto_stories_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    message: message,
    subtitle: subtitle,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

class SubjectsLoadingSkeleton extends StatelessWidget {
  const SubjectsLoadingSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => Skeleton(child: _shapes(context));

  Widget _shapes(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 16),
          child: LiquidGlassSurface(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(18),
            fillOpacity: 0.28,
            borderOpacity: 0.5,
            child: SizedBox(
              height: 120,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 56, height: 22),
                        const SizedBox(height: 12),
                        SkeletonBox(width: double.infinity, height: 18),
                        const SizedBox(height: 8),
                        SkeletonBox(width: 140, height: 14),
                        const SizedBox(height: 8),
                        SkeletonBox(width: 190, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SkeletonBox(width: 58, height: 58, radius: 999),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Lesson rows while a course's lessons load: the number and two lines.
class LessonsLoadingSkeleton extends StatelessWidget {
  const LessonsLoadingSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : 12),
              child: SkeletonCard(
                radius: 14,
                padding: const EdgeInsets.all(14),
                child: SkeletonListRow(
                  leadingSize: 36,
                  leadingRadius: 999,
                  titleWidth: i.isEven ? 190 : 150,
                  subtitleWidth: 90,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A whole course page while it loads: the cover, the facts card and the
/// lessons. The back button stays real so the student is never stuck.
class SubjectDetailsLoadingSkeleton extends StatelessWidget {
  const SubjectDetailsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Stack(
          children: [
            Skeleton(child: SkeletonBox(height: 248 + top, radius: 0)),
            PositionedDirectional(
              top: top + 8,
              start: 8,
              child: const BackButton(),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Skeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonCard(
                  radius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonBox(width: 70, height: 30, radius: 999),
                          SizedBox(width: 8),
                          SkeletonBox(width: 70, height: 30, radius: 999),
                          SizedBox(width: 8),
                          SkeletonBox(width: 70, height: 30, radius: 999),
                        ],
                      ),
                      SizedBox(height: 16),
                      SkeletonBox(height: 12),
                      SizedBox(height: 8),
                      SkeletonBox(width: 220, height: 12),
                      SizedBox(height: 20),
                      SkeletonBox(height: 8, radius: 999),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SkeletonBox(width: 90, height: 20),
                const SizedBox(height: 12),
                const LessonsLoadingSkeleton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SubjectsErrorState extends StatelessWidget {
  const SubjectsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(24),
      fillOpacity: 0.3,
      borderOpacity: 0.52,
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.of(context).error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.of(context).t(message),
            style: AppTextStyles.bodyOf(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(AppStrings.of(context).t('إعادة المحاولة')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.of(context).primary,
              side: BorderSide(
                color: AppColors.of(context).accent.withValues(alpha: 0.6),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
