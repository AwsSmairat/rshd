import 'package:flutter/material.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/skeleton.dart';
import '../../announcements/widgets/announcement_image_carousel.dart';

/// The home page while the dashboard loads for the first time: the
/// continue-learning cards, the banner and the suggested courses, in place.
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = AppLayoutMetrics.of(context).sectionSpacing;

    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 150, height: 18),
                const SizedBox(height: 12),
                for (var i = 0; i < 2; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  const _ContinueCardShape(),
                ],
                SizedBox(height: gap),
                const AspectRatio(
                  aspectRatio: AnnouncementImageCarousel.aspectRatio,
                  child: SkeletonBox(height: double.infinity, radius: 24),
                ),
                SizedBox(height: gap),
                const SkeletonBox(width: 110, height: 18),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Suggested courses run off the edge, as the real row does.
          SizedBox(
            height: 238,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: AppLayoutMetrics.of(context).horizontalPadding,
              ),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const _SuggestedCardShape(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCardShape extends StatelessWidget {
  const _ContinueCardShape();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      height: 132,
      radius: 24,
      child: Row(
        children: [
          SkeletonBox.circle(size: 48),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 110, height: 12),
                SizedBox(height: 16),
                SkeletonBox(height: 6, radius: 999),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedCardShape extends StatelessWidget {
  const _SuggestedCardShape();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 230,
      child: SkeletonCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: SkeletonBox(height: double.infinity, radius: 20),
            ),
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 150, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 90, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
