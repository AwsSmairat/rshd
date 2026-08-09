import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/quiz_model.dart';
import '../widgets/quiz_question_card.dart';
import 'quizzes_controller.dart';

class QuizAttemptScreen extends ConsumerStatefulWidget {
  const QuizAttemptScreen({super.key, required this.quizId});

  final int quizId;

  @override
  ConsumerState<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends ConsumerState<QuizAttemptScreen> {
  Timer? _timer;
  bool _timeExpiredSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final started = await ref
          .read(quizAttemptControllerProvider(widget.quizId).notifier)
          .start();
      if (started && mounted) {
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final controller = ref.read(
        quizAttemptControllerProvider(widget.quizId).notifier,
      );
      final state = ref.read(quizAttemptControllerProvider(widget.quizId));
      final remaining = state.remainingSeconds;

      if (remaining == null) {
        return;
      }

      if (remaining <= 1) {
        controller.tickTimer();
        _timer?.cancel();
        _submitOnTimeExpired();
        return;
      }

      controller.tickTimer();
    });
  }

  Future<void> _submitOnTimeExpired() async {
    if (_timeExpiredSubmitting || !mounted) {
      return;
    }
    _timeExpiredSubmitting = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('انتهى وقت الاختبار، جاري التسليم...')),
    );

    await _submit(force: true);
  }

  Future<void> _submit({bool force = false}) async {
    final state = ref.read(quizAttemptControllerProvider(widget.quizId));

    if (!force && !state.allQuestionsAnswered) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('أسئلة غير مجابة'),
          content: const Text(
            'لم تجب على جميع الأسئلة. هل تريد تسليم الاختبار؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إكمال الإجابات'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تسليم الآن'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    final result = await ref
        .read(quizAttemptControllerProvider(widget.quizId).notifier)
        .submit();

    if (!mounted || result == null) {
      return;
    }

    _timer?.cancel();

    final quiz = state.quiz;
    ref
        .read(quizzesListControllerProvider.notifier)
        .upsertQuiz(
          (ref
                      .read(quizzesListControllerProvider.notifier)
                      .findById(widget.quizId) ??
                  quiz ??
                  QuizModel(id: widget.quizId, subjectId: 0, title: ''))
              .copyWith(latestAttempt: result),
        );

    context.go(
      AppRoutes.quizResult(widget.quizId),
      extra: {
        'score': result.score ?? '0',
        'questionsCount':
            result.questionsCount ??
            quiz?.questions.length ??
            quiz?.questionsCount ??
            0,
        'submittedAt': result.submittedAt ?? '',
        'quizTitle': quiz?.title ?? 'الاختبار',
      },
    );
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizAttemptControllerProvider(widget.quizId));
    final controller = ref.read(
      quizAttemptControllerProvider(widget.quizId).notifier,
    );

    ref.listen(quizAttemptControllerProvider(widget.quizId), (previous, next) {
      _handleUnauthorized(next.errorMessage);
      if (next.status == QuizAttemptStatus.error &&
          next.errorMessage != null &&
          next.status != QuizAttemptStatus.submitting) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.quiz?.title ?? 'الاختبار'),
        actions: [
          if (state.remainingSeconds != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: Text(
                  _formatTime(state.remainingSeconds!),
                  style: AppTextStyles.body.copyWith(
                    color: state.remainingSeconds! <= 60
                        ? AppColors.error
                        : AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state, controller),
    );
  }

  Widget _buildBody(QuizAttemptState state, QuizAttemptController controller) {
    switch (state.status) {
      case QuizAttemptStatus.loading:
        return const LoadingWidget(message: 'جاري بدء الاختبار...');
      case QuizAttemptStatus.error:
        final isRetakeBlocked =
            state.errorMessage?.contains('إعادة الاختبار غير مسموحة') ?? false;
        return ErrorView(
          message: state.errorMessage ?? 'تعذر بدء الاختبار',
          onRetry: isRetakeBlocked
              ? () {
                  if (mounted) {
                    context.pop();
                  }
                }
              : () async {
                  final started = await controller.start();
                  if (started && mounted) {
                    _startTimer();
                  }
                },
          retryLabel: isRetakeBlocked ? 'العودة' : 'إعادة المحاولة',
        );
      case QuizAttemptStatus.loaded:
      case QuizAttemptStatus.submitting:
        final question = state.currentQuestion;
        final quiz = state.quiz;
        if (question == null || quiz == null) {
          return ErrorView(
            message: 'لا توجد أسئلة في هذا الاختبار',
            onRetry: () => context.pop(),
          );
        }

        final isSubmitting = state.status == QuizAttemptStatus.submitting;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: QuizQuestionCard(
                      question: question,
                      questionNumber: state.currentQuestionIndex + 1,
                      totalQuestions: quiz.questions.length,
                      selectedAnswerId: state.selectedAnswers[question.id],
                      onAnswerSelected: (answerId) {
                        controller.selectAnswer(question.id, answerId);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isSubmitting || state.currentQuestionIndex <= 0
                            ? null
                            : controller.goToPreviousQuestion,
                        child: const Text('السابق'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: state.isLastQuestion
                          ? AppButton(
                              label: 'تسليم',
                              isLoading: isSubmitting,
                              onPressed: isSubmitting ? null : _submit,
                            )
                          : OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : controller.goToNextQuestion,
                              child: const Text('التالي'),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case QuizAttemptStatus.submitted:
        return const LoadingWidget(message: 'جاري عرض النتيجة...');
    }
  }
}
