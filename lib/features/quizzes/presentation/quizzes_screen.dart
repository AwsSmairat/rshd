import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../../../core/widgets/responsive_content.dart';
import '../widgets/quiz_card.dart';
import '../widgets/quizzes_header.dart';
import '../widgets/quizzes_state_views.dart';
import 'quizzes_controller.dart';

class QuizzesScreen extends ConsumerStatefulWidget {
  const QuizzesScreen({super.key});

  @override
  ConsumerState<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends ConsumerState<QuizzesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizzesListControllerProvider.notifier).load();
    });
  }

  Future<void> _refresh() {
    return ref.read(quizzesListControllerProvider.notifier).load(refresh: true);
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizzesListControllerProvider);

    ref.listen(quizzesListControllerProvider, (previous, next) {
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
            const SliverToBoxAdapter(child: QuizzesHeader()),
            ResponsiveSliverContent(sliver: _buildContent(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(QuizzesListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const SliverToBoxAdapter(
          child: QuizzesLoadingSkeleton(count: 3),
        );
      case FeatureLoadStatus.empty:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: QuizzesEmptyState()),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: QuizzesErrorState(
              message: state.errorMessage ?? 'تعذر تحميل الاختبارات',
              onRetry: () =>
                  ref.read(quizzesListControllerProvider.notifier).load(),
            ),
          ),
        );
      case FeatureLoadStatus.loaded:
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final quiz = state.quizzes[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == state.quizzes.length - 1 ? 0 : 16,
              ),
              child: QuizCard(
                quiz: quiz,
                onTap: () => context.push(AppRoutes.quizDetails(quiz.id)),
              ),
            );
          }, childCount: state.quizzes.length),
        );
    }
  }
}
