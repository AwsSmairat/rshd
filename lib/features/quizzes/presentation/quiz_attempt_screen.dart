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
import '../data/models/quiz_model.dart';
import '../widgets/quiz_question_card.dart';
import 'quizzes_controller.dart';
import '../../../core/l10n/app_strings.dart';

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
      SnackBar(
        content: Text(
          AppStrings.of(context).t('انتهى وقت الاختبار، جاري التسليم...'),
        ),
      ),
    );

    await _submit(force: true);
  }

  Future<void> _submit({bool force = false}) async {
    final state = ref.read(quizAttemptControllerProvider(widget.quizId));

    if (!force && !state.allQuestionsAnswered) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.of(context).t('أسئلة غير مجابة')),
          content: Text(
            AppStrings.of(
              context,
            ).t('لم تجب على جميع الأسئلة. هل تريد تسليم الاختبار؟'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.of(context).t('إكمال الإجابات')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.of(context).t('تسليم الآن')),
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Leaving mid-quiz drops the answers given so far; ask first.
  Future<void> _confirmLeave() async {
    final strings = AppStrings.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('الخروج من الاختبار؟')),
        content: Text(strings.t('لن تُحفظ إجاباتك الحالية إذا خرجت الآن.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.t('متابعة الاختبار')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.of(context).error,
            ),
            child: Text(strings.t('خروج')),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _timer?.cancel();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizAttemptControllerProvider(widget.quizId));
    final controller = ref.read(
      quizAttemptControllerProvider(widget.quizId).notifier,
    );

    ref.listen(quizAttemptControllerProvider(widget.quizId), (previous, next) {
      final message = next.errorMessage;
      if (message != null &&
          message != previous?.errorMessage &&
          next.status != QuizAttemptStatus.submitting) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).t(message))),
        );
      }
    });

    final inProgress =
        state.status == QuizAttemptStatus.loaded ||
        state.status == QuizAttemptStatus.submitting;

    return PopScope(
      canPop: !inProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state.status == QuizAttemptStatus.loaded) {
          _confirmLeave();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _AttemptTopBar(
                title: state.quiz?.title ?? 'الاختبار',
                remaining: state.remainingSeconds,
                formatTime: _formatTime,
                onClose: inProgress
                    ? (state.status == QuizAttemptStatus.loaded
                          ? _confirmLeave
                          : null)
                    : () => context.pop(),
              ),
              Expanded(child: _buildBody(state, controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(QuizAttemptState state, QuizAttemptController controller) {
    switch (state.status) {
      case QuizAttemptStatus.loading:
        return LoadingWidget(
          message: AppStrings.of(context).t('جاري بدء الاختبار...'),
        );
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
            message: AppStrings.of(context).t('لا توجد أسئلة في هذا الاختبار'),
            onRetry: () => context.pop(),
          );
        }

        final isSubmitting = state.status == QuizAttemptStatus.submitting;
        final total = quiz.questions.length;
        final answered = quiz.questions
            .where((q) => state.selectedAnswers.containsKey(q.id))
            .length;

        return Column(
          children: [
            _Centered(
              child: _ProgressSection(
                total: total,
                current: state.currentQuestionIndex,
                answered: answered,
                isAnswered: (index) =>
                    state.selectedAnswers.containsKey(quiz.questions[index].id),
                onJump: isSubmitting ? null : controller.goToQuestion,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                child: _Centered(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: QuizQuestionCard(
                      key: ValueKey(question.id),
                      question: question,
                      questionNumber: state.currentQuestionIndex + 1,
                      totalQuestions: total,
                      selectedAnswerId: state.selectedAnswers[question.id],
                      onAnswerSelected: isSubmitting
                          ? (_) {}
                          : (answerId) =>
                                controller.selectAnswer(question.id, answerId),
                    ),
                  ),
                ),
              ),
            ),
            _BottomBar(
              canGoBack: !isSubmitting && state.currentQuestionIndex > 0,
              isLast: state.isLastQuestion,
              isSubmitting: isSubmitting,
              onBack: controller.goToPreviousQuestion,
              onNext: controller.goToNextQuestion,
              onSubmit: _submit,
            ),
          ],
        );
      case QuizAttemptStatus.submitted:
        return LoadingWidget(
          message: AppStrings.of(context).t('جاري عرض النتيجة...'),
        );
    }
  }
}

/// Keeps the quiz at a readable width on iPad and landscape.
class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width >= 700 ? 32.0 : 16.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: child,
        ),
      ),
    );
  }
}

class _AttemptTopBar extends StatelessWidget {
  const _AttemptTopBar({
    required this.title,
    required this.remaining,
    required this.formatTime,
    required this.onClose,
  });

  final String title;
  final int? remaining;
  final String Function(int) formatTime;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            IconButton(
              tooltip: strings.t('خروج'),
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: colors.text),
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                backgroundColor: colors.cardWhite.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.t(title),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleOf(context).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (remaining != null)
              _TimerPill(seconds: remaining!, label: formatTime(remaining!))
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.seconds, required this.label});

  final int seconds;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final urgent = seconds <= 60;
    final warning = seconds <= 300;
    final tint = urgent
        ? colors.error
        : (warning ? colors.darkGold : colors.primary);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = urgent || warning || !isDark ? tint : colors.text;

    return Semantics(
      label: '${AppStrings.of(context).t('الوقت المتبقي')} $label',
      liveRegion: urgent,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: isDark ? 0.22 : 0.09),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 18, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.bodyOf(context).copyWith(
                fontSize: 15,
                height: 1,
                fontWeight: FontWeight.w800,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How far along the student is, and a strip to jump to any question.
class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.total,
    required this.current,
    required this.answered,
    required this.isAnswered,
    required this.onJump,
  });

  final int total;
  final int current;
  final int answered;
  final bool Function(int index) isAnswered;
  final ValueChanged<int>? onJump;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = total == 0 ? 0.0 : answered / total;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                strings.isEnglish
                    ? 'Answered $answered of $total'
                    : 'أجبت عن $answered من $total',
                style: AppTextStyles.bodyOf(context).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${(fraction * 100).round()}%',
                textDirection: TextDirection.ltr,
                style: AppTextStyles.bodyOf(context).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.darkGold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: colors.primary.withValues(
                  alpha: isDark ? 0.25 : 0.08,
                ),
                valueColor: AlwaysStoppedAnimation(colors.accent),
              ),
            ),
          ),
          if (total > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: total,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _QuestionDot(
                  number: index + 1,
                  isCurrent: index == current,
                  isAnswered: isAnswered(index),
                  onTap: onJump == null ? null : () => onJump!(index),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionDot extends StatelessWidget {
  const _QuestionDot({
    required this.number,
    required this.isCurrent,
    required this.isAnswered,
    required this.onTap,
  });

  final int number;
  final bool isCurrent;
  final bool isAnswered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filled = isAnswered;
    final fill = filled
        ? (isDark ? colors.accent : colors.primary)
        : colors.cardWhite.withValues(alpha: isDark ? 0.9 : 0.85);
    final fg = filled ? (isDark ? colors.primary : colors.white) : colors.text;

    return Semantics(
      button: true,
      selected: isCurrent,
      label: strings.isEnglish
          ? 'Question $number${isAnswered ? ', answered' : ''}'
          : 'السؤال $number${isAnswered ? '، تمت الإجابة' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent
                  ? colors.accent
                  : colors.primary.withValues(alpha: isDark ? 0.25 : 0.1),
              width: isCurrent ? 2.4 : 1,
            ),
          ),
          child: Text(
            '$number',
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: 14,
              height: 1,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.canGoBack,
    required this.isLast,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final bool canGoBack;
  final bool isLast;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.primary.withValues(alpha: 0.06)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 12, bottom: 12 + bottomInset),
        child: _Centered(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: canGoBack ? onBack : null,
                    icon: Icon(
                      rtl
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                    ),
                    label: Text(strings.t('السابق')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.text,
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: 0.14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: isLast
                      ? AppButton(
                          label: strings.t('تسليم الاختبار'),
                          isLoading: isSubmitting,
                          onPressed: isSubmitting ? null : onSubmit,
                        )
                      : FilledButton.icon(
                          onPressed: isSubmitting ? null : onNext,
                          iconAlignment: IconAlignment.end,
                          icon: Icon(
                            rtl
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                          ),
                          label: Text(strings.t('التالي')),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
