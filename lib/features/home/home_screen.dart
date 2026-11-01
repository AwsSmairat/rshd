import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/rshd_refresh_indicator.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/layout/app_layout_metrics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/responsive_content.dart';
import '../announcements/widgets/announcement_image_carousel.dart';
import '../auth/presentation/auth_controller.dart';
import 'home_controller.dart';
import 'home_dashboard_model.dart';
import '../subjects/data/models/subject_model.dart';
import 'widgets/continue_learning_card.dart';
import 'widgets/home_reveal.dart';
import 'widgets/home_search_field.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/suggested_subjects_section.dart';
import 'widgets/upcoming_assignments_section.dart';

/// The Home tab: a short, ordered overview — greeting and search, featured
/// announcements, what to continue, what to try next, and what is
/// due. Full lists live in their own tabs.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(homeControllerProvider);
      if (state.status == HomeLoadStatus.initial) {
        _loadDashboard();
      }
    });
  }

  void _loadDashboard({bool refresh = false}) {
    final userName = ref.read(authControllerProvider).user?.name;
    ref
        .read(homeControllerProvider.notifier)
        .load(refresh: refresh, fallbackStudentName: userName);
  }

  Future<void> _refresh() {
    final userName = ref.read(authControllerProvider).user?.name;
    return ref
        .read(homeControllerProvider.notifier)
        .load(refresh: true, fallbackStudentName: userName);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: _buildBody(state),
    );
  }

  Widget _buildBody(HomeState state) {
    if (state.status == HomeLoadStatus.error && state.dashboard == null) {
      return ErrorView(
        message: state.errorMessage ?? AppStrings.of(context).loadingHome,
        onRetry: () => _loadDashboard(),
      );
    }

    final dashboard = state.dashboard;
    final isBusy =
        state.status == HomeLoadStatus.initial ||
        state.status == HomeLoadStatus.loading ||
        state.status == HomeLoadStatus.refreshing;
    final userName =
        dashboard?.studentName ??
        ref.watch(authControllerProvider).user?.name ??
        AppStrings.of(context).rshdStudentFallback;
    final gap = AppLayoutMetrics.of(context).sectionSpacing;

    final banners = (dashboard?.featuredAnnouncements ?? const [])
        .where((item) => item.hasCarouselImage)
        .toList();
    final suggested = _suggestedSubjects(dashboard);

    var order = 0;
    Widget section(Widget child, {double top = 0}) => SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: HomeReveal(order: order++, child: child),
      ),
    );

    return RshdRefreshIndicator(
      onRefresh: isBusy ? () async {} : _refresh,
      color: AppColors.of(context).darkGold,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: ResponsiveContent(
                child: HomeTopBar(
                  studentName: userName,
                  unreadCount: dashboard?.unreadNotificationsCount ?? 0,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedOpacity(
              opacity: isBusy ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.of(context).accent,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
          section(
            ResponsiveContent(
              child: HomeSearchField(
                subjects: [
                  ...?dashboard?.subjects,
                  ...?dashboard?.catalogSubjects,
                ],
              ),
            ),
            top: 10,
          ),
          if (dashboard != null)
            section(
              ContinueLearningSection(
                subjects: dashboard.continueLearningSubjects,
                progressFor: dashboard.resolvedProgressPercent,
              ),
              top: 24,
            ),
          if (banners.isNotEmpty)
            section(
              ResponsiveContent(
                child: AnnouncementImageCarousel(announcements: banners),
              ),
              top: gap,
            ),
          if (suggested.isNotEmpty)
            section(
              ResponsiveContent(
                child: SuggestedSubjectsSection(subjects: suggested),
              ),
              top: gap,
            ),
          section(
            UpcomingAssignmentsSection(
              assignments: dashboard?.upcomingAssignments ?? const [],
              quizzes: dashboard?.featuredQuizzes ?? const [],
            ),
            top: gap,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  /// Catalogue courses the student has not joined, newest first as served.
  List<SubjectModel> _suggestedSubjects(HomeDashboardModel? dashboard) {
    if (dashboard == null) return const [];
    final enrolled = dashboard.subjects.map((s) => s.id).toSet();
    return dashboard.catalogSubjects
        .where((s) => !enrolled.contains(s.id) && !s.isEnrollmentActive)
        .take(8)
        .toList();
  }
}
