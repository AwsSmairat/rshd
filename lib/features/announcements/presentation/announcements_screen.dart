import 'package:flutter/material.dart';

import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/stagger_reveal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/rshd_refresh_indicator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../../subjects/widgets/subjects_header.dart';
import '../data/models/announcement_model.dart';
import '../widgets/announcement_card.dart';
import 'announcements_controller.dart';
import '../../../core/l10n/app_strings.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementsListControllerProvider.notifier).load();
    });
  }

  Future<void> _refresh() {
    return ref
        .read(announcementsListControllerProvider.notifier)
        .load(refresh: true);
  }

  void _openAnnouncement(AnnouncementModel announcement) {
    context.push(
      AppRoutes.announcementDetails(announcement.id),
      extra: announcement,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementsListControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RshdRefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.of(context).secondary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SubjectsHeader(
                title: AppStrings.of(context).t('الإعلانات'),
                backgroundIcon: Icons.campaign_outlined,
              ),
            ),
            _buildContent(state),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AnnouncementsListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return ResponsiveSliverContent(
          padding: AppLayoutMetrics.of(context).pagePadding(top: 16, bottom: 0),
          sliver: const SliverToBoxAdapter(child: _AnnouncementsSkeleton()),
        );
      case FeatureLoadStatus.empty:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(AppStrings.of(context).t('لا توجد إعلانات حالياً')),
          ),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          child: ErrorView(
            message: state.errorMessage ?? 'تعذر تحميل الإعلانات',
            onRetry: () =>
                ref.read(announcementsListControllerProvider.notifier).load(),
          ),
        );
      case FeatureLoadStatus.loaded:
        final metrics = AppLayoutMetrics.of(context);

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: ResponsiveContent(
                padding: EdgeInsets.fromLTRB(
                  metrics.horizontalPadding,
                  16,
                  metrics.horizontalPadding,
                  8,
                ),
                child: Row(
                  children: [
                    Text(
                      AppStrings.of(context).t('آخر الإعلانات'),
                      style: AppTextStyles.subtitleOf(context).copyWith(
                        fontSize: metrics.sectionTitleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppStrings.of(
                        context,
                      ).t('${state.announcements.length} إعلان'),
                      style: AppTextStyles.bodyOf(context).copyWith(
                        fontSize: 12,
                        color: AppColors.of(context).textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                metrics.outerHorizontalInset,
                0,
                metrics.outerHorizontalInset,
                24,
              ),
              sliver: SliverConstrainedCrossAxis(
                maxExtent: metrics.contentMaxWidth,
                sliver: SliverList.separated(
                  itemCount: state.announcements.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final announcement = state.announcements[index];
                    return StaggerReveal(
                      order: index,
                      child: AnnouncementCard(
                        announcement: announcement,
                        onTap: () => _openAnnouncement(announcement),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
    }
  }
}

/// Announcement cards while the list loads: text beside a thumbnail.
class _AnnouncementsSkeleton extends StatelessWidget {
  const _AnnouncementsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 120, height: 18),
          const SizedBox(height: 14),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonBox(width: 70, height: 18, radius: 999),
                          const SizedBox(height: 10),
                          SkeletonBox(width: i.isEven ? 210 : 170, height: 15),
                          const SizedBox(height: 8),
                          const SkeletonBox(height: 11),
                          const SizedBox(height: 6),
                          const SkeletonBox(width: 150, height: 11),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    const SkeletonBox(width: 72, height: 72, radius: 14),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
