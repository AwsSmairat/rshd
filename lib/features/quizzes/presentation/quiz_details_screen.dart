import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../widgets/liquid_glass_quiz_info_card.dart';
import '../widgets/luxury_quiz_header.dart';
import '../widgets/quiz_not_attempted_card.dart';
import '../widgets/quiz_result_summary_card.dart';
import '../widgets/quiz_score_helper.dart';
import '../widgets/quiz_stats_grid.dart';
import '../widgets/result_action_buttons.dart';
import '../widgets/quizzes_state_views.dart';
import 'quizzes_controller.dart';

class QuizDetailsScreen extends ConsumerStatefulWidget {
  const QuizDetailsScreen({
    super.key,
    required this.quizId,
  });

  final int quizId;

  @override
  ConsumerState<QuizDetailsScreen> createState() => _QuizDetailsScreenState();
}

class _QuizDetailsScreenState extends ConsumerState<QuizDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  void _loadDetails() {
    final cached =
        ref.read(quizzesListControllerProvider.notifier).findById(widget.quizId);
    ref
        .read(quizDetailsControllerProvider(widget.quizId).notifier)
        .load(widget.quizId, cached: cached);
  }

  Future<void> _startQuiz() async {
    if (!mounted) {
      return;
    }
    context.push(AppRoutes.quizAttempt(widget.quizId));
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizDetailsControllerProvider(widget.quizId));

    ref.listen(quizDetailsControllerProvider(widget.quizId), (previous, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: LuxuryQuizHeader(title: 'تفاصيل الاختبار'),
          ),
          ResponsiveSliverContent(
            padding: AppLayoutMetrics.of(context).pagePadding(
              top: 8,
              bottom: 28,
            ),
            sliver: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(QuizDetailsState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const SliverToBoxAdapter(
          child: QuizzesLoadingSkeleton(count: 2),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: QuizzesErrorState(
              message: state.errorMessage ?? 'تعذر تحميل الاختبار',
              onRetry: _loadDetails,
            ),
          ),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final quiz = state.quiz;
        if (quiz == null) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: QuizzesErrorState(
                message: 'الاختبار غير موجود',
                onRetry: _loadDetails,
              ),
            ),
          );
        }

        final score = QuizScoreHelper.parseScore(quiz.latestAttempt?.score);
        final startLabel =
            quiz.isCompleted ? 'بدء الاختبار مرة أخرى' : 'بدء الاختبار';

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LiquidGlassQuizInfoCard(quiz: quiz),
              const SizedBox(height: 16),
              QuizStatsGrid(quiz: quiz),
              const SizedBox(height: 16),
              if (score != null)
                QuizResultSummaryCard(score: score)
              else
                const QuizNotAttemptedCard(),
              const SizedBox(height: 24),
              ResultActionButtons(
                primaryLabel: startLabel,
                onPrimary: quiz.isActive ? _startQuiz : null,
              ),
            ],
          ),
        );
    }
  }
}
