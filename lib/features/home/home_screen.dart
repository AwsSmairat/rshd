import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/layout/app_layout_metrics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_view.dart';
import '../auth/presentation/auth_controller.dart';
import '../announcements/widgets/home_announcements_section.dart';
import 'home_controller.dart';
import 'widgets/academic_departments_section.dart';
import 'widgets/continue_learning_card.dart';
import 'widgets/dashboard_summary_card.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/recent_subjects_section.dart';
import 'widgets/upcoming_assignments_section.dart';
import 'widgets/welcome_header.dart';

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
    ref.read(homeControllerProvider.notifier).load(
          refresh: refresh,
          fallbackStudentName: userName,
        );
  }

  Future<void> _refresh() {
    final userName = ref.read(authControllerProvider).user?.name;
    return ref.read(homeControllerProvider.notifier).load(
          refresh: true,
          fallbackStudentName: userName,
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
    final state = ref.watch(homeControllerProvider);

    ref.listen(homeControllerProvider, (previous, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      body: _buildBody(state),
    );
  }

  Widget _buildBody(HomeState state) {
    if (state.status == HomeLoadStatus.error && state.dashboard == null) {
      return ErrorView(
        message: state.errorMessage ?? 'تعذر تحميل الصفحة الرئيسية',
        onRetry: () => _loadDashboard(),
      );
    }

    final dashboard = state.dashboard;
    final isLoading = state.status == HomeLoadStatus.initial ||
        state.status == HomeLoadStatus.loading;
    final isRefreshing = state.status == HomeLoadStatus.refreshing;
    final userName = dashboard?.studentName ??
        ref.watch(authControllerProvider).user?.name ??
        'طالب RSHD';

    final metrics = AppLayoutMetrics.of(context);
    final sectionGap = metrics.sectionSpacing;

    return RefreshIndicator(
      onRefresh: isLoading ? () async {} : _refresh,
      color: AppColors.secondary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: WelcomeHeader(
              studentName: userName,
              unreadCount: dashboard?.unreadNotificationsCount ?? 0,
            ),
          ),
          if (isLoading || isRefreshing)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.accent,
                backgroundColor: Colors.transparent,
              ),
            ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: DashboardSummaryGrid(
                subjectsCount: dashboard?.subjectsCount ?? 0,
                unsubmittedAssignmentsCount:
                    dashboard?.unsubmittedAssignmentsCount ?? 0,
                availableQuizzesCount: dashboard?.availableQuizzesCount ?? 0,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: QuickActionGrid()),
          if (dashboard?.continueLearningSubject != null) ...[
            SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
            SliverToBoxAdapter(
              child: ContinueLearningCard(
                subject: dashboard!.continueLearningSubject!,
                progressPercent: dashboard.resolvedProgressPercent(
                  dashboard.continueLearningSubject!,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
          SliverToBoxAdapter(
            child: HomeAnnouncementsSection(
              announcements: dashboard?.featuredAnnouncements ?? const [],
              loadFailed: dashboard?.announcementsLoadFailed ?? false,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
          SliverToBoxAdapter(
            child: AcademicDepartmentsSection(
              subjects: dashboard?.catalogSubjects ?? const [],
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
          SliverToBoxAdapter(
            child: RecentSubjectsSection(
              subjects: dashboard?.recentSubjects ?? const [],
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
          SliverToBoxAdapter(
            child: UpcomingAssignmentsSection(
              assignments: dashboard?.upcomingAssignments ?? const [],
              quizzes: dashboard?.featuredQuizzes ?? const [],
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).bottom + 24,
            ),
          ),
        ],
      ),
    );
  }
}
