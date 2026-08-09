import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/widgets/subjects_header.dart';
import '../widgets/quiz_result_summary_card.dart';
import '../widgets/quiz_score_helper.dart';
import '../widgets/quiz_submission_success_card.dart';
import '../widgets/quiz_stats_grid.dart';
import '../widgets/result_action_buttons.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.quizId,
    required this.score,
    required this.questionsCount,
    required this.submittedAt,
    required this.quizTitle,
  });

  final int quizId;
  final String score;
  final int questionsCount;
  final String submittedAt;
  final String quizTitle;

  @override
  Widget build(BuildContext context) {
    final parsedScore = QuizScoreHelper.parseScore(score) ?? 0;
    final scoreDisplay = QuizScoreHelper.formatScore(parsedScore);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SubjectsHeader(
            title: 'نتيجة الاختبار',
            backgroundIcon: Icons.emoji_events_outlined,
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                ResponsiveSliverContent(
                  padding: AppLayoutMetrics.of(
                    context,
                  ).pagePadding(top: 8, bottom: 28),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        QuizSubmissionSuccessCard(quizTitle: quizTitle),
                        const SizedBox(height: 16),
                        QuizResultSummaryCard(
                          score: parsedScore,
                          title: 'نتيجتك',
                        ),
                        const SizedBox(height: 16),
                        QuizStatsGrid(
                          submittedAt: submittedAt,
                          questionsCount: questionsCount,
                          scoreDisplay: scoreDisplay,
                          finishTimeLabel: 'وقت التسليم',
                          finishDateLabel: 'تاريخ التسليم',
                        ),
                        const SizedBox(height: 24),
                        ResultActionButtons(
                          primaryLabel: 'العودة للاختبارات',
                          onPrimary: () => context.go(AppRoutes.quizzes),
                          secondaryLabel: 'بدء الاختبار مرة أخرى',
                          onSecondary: () =>
                              context.push(AppRoutes.quizAttempt(quizId)),
                          tertiaryLabel: 'الصفحة الرئيسية',
                          onTertiary: () => context.go(AppRoutes.home),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
