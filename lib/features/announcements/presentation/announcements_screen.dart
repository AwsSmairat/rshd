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
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../../subjects/widgets/subjects_header.dart';
import '../data/models/announcement_model.dart';
import '../widgets/announcement_card.dart';
import 'announcements_controller.dart';

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

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementsListControllerProvider);

    ref.listen(announcementsListControllerProvider, (previous, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.secondary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: SubjectsHeader(
                title: 'الإعلانات',
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
        return const SliverFillRemaining(
          child: LoadingWidget(message: 'جاري تحميل الإعلانات...'),
        );
      case FeatureLoadStatus.empty:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('لا توجد إعلانات حالياً')),
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
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'آخر الإعلانات',
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: metrics.sectionTitleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.announcements.length} إعلان',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.textMuted,
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
