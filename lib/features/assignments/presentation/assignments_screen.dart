import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../widgets/assignment_card.dart';
import '../widgets/assignments_header.dart';
import '../../../core/widgets/responsive_content.dart';
import '../widgets/assignments_state_views.dart';
import 'assignments_controller.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentsListControllerProvider.notifier).load();
    });
  }

  Future<void> _refresh() {
    return ref
        .read(assignmentsListControllerProvider.notifier)
        .load(refresh: true);
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentsListControllerProvider);

    ref.listen(assignmentsListControllerProvider, (previous, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.of(context).darkGold,
        backgroundColor: AppColors.of(context).cardWhite,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: AssignmentsHeader()),
            ResponsiveSliverContent(sliver: _buildContent(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AssignmentsListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const SliverToBoxAdapter(
          child: AssignmentsLoadingSkeleton(count: 3),
        );
      case FeatureLoadStatus.empty:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: AssignmentsEmptyState()),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: AssignmentsErrorState(
              message: state.errorMessage ?? 'تعذر تحميل الواجبات',
              onRetry: () =>
                  ref.read(assignmentsListControllerProvider.notifier).load(),
            ),
          ),
        );
      case FeatureLoadStatus.loaded:
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final assignment = state.assignments[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == state.assignments.length - 1 ? 0 : 16,
              ),
              child: AssignmentCard(
                assignment: assignment,
                onTap: () =>
                    context.push(AppRoutes.assignmentDetails(assignment.id)),
              ),
            );
          }, childCount: state.assignments.length),
        );
    }
  }
}
