import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
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
      body: RefreshIndicator(
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
        return SliverFillRemaining(
          child: LoadingWidget(message: AppStrings.of(context).t('جاري تحميل الإعلانات...')),
        );
      case FeatureLoadStatus.empty:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(AppStrings.of(context).t('لا توجد إعلانات حالياً'))),
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
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.of(context).accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(AppStrings.of(context).t('آخر الإعلانات'),
                      style: AppTextStyles.subtitleOf(context).copyWith(
                        fontSize: metrics.sectionTitleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(AppStrings.of(context).t('${state.announcements.length} إعلان'),
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
                    return AnnouncementCard(
                      announcement: announcement,
                      onTap: () => _openAnnouncement(announcement),
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
