import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/models/quiz_attempt_model.dart';
import '../data/models/quiz_model.dart';
import '../data/models/quiz_question_model.dart';
import '../data/quizzes_repository.dart';

class QuizzesListState {
  const QuizzesListState({
    this.status = FeatureLoadStatus.initial,
    this.quizzes = const [],
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final List<QuizModel> quizzes;
  final String? errorMessage;

  QuizzesListState copyWith({
    FeatureLoadStatus? status,
    List<QuizModel>? quizzes,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QuizzesListState(
      status: status ?? this.status,
      quizzes: quizzes ?? this.quizzes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class QuizDetailsState {
  const QuizDetailsState({
    this.status = FeatureLoadStatus.initial,
    this.quiz,
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final QuizModel? quiz;
  final String? errorMessage;

  QuizDetailsState copyWith({
    FeatureLoadStatus? status,
    QuizModel? quiz,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QuizDetailsState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

enum QuizAttemptStatus {
  loading,
  loaded,
  submitting,
  submitted,
  error,
}

class QuizAttemptState {
  const QuizAttemptState({
    this.status = QuizAttemptStatus.loading,
    this.attemptId,
    this.quiz,
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.remainingSeconds,
    this.result,
    this.errorMessage,
  });

  final QuizAttemptStatus status;
  final int? attemptId;
  final QuizModel? quiz;
  final int currentQuestionIndex;
  final Map<int, int> selectedAnswers;
  final int? remainingSeconds;
  final QuizAttemptModel? result;
  final String? errorMessage;

  QuizQuestionModel? get currentQuestion {
    final questions = quiz?.questions ?? [];
    if (questions.isEmpty ||
        currentQuestionIndex < 0 ||
        currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  bool get isLastQuestion {
    final questions = quiz?.questions ?? [];
    return questions.isNotEmpty &&
        currentQuestionIndex >= questions.length - 1;
  }

  bool get allQuestionsAnswered {
    final questions = quiz?.questions ?? [];
    if (questions.isEmpty) {
      return false;
    }
    for (final question in questions) {
      if (!selectedAnswers.containsKey(question.id)) {
        return false;
      }
    }
    return true;
  }

  List<int> get unansweredQuestionIds {
    final questions = quiz?.questions ?? [];
    return questions
        .where((question) => !selectedAnswers.containsKey(question.id))
        .map((question) => question.id)
        .toList();
  }

  QuizAttemptState copyWith({
    QuizAttemptStatus? status,
    int? attemptId,
    QuizModel? quiz,
    int? currentQuestionIndex,
    Map<int, int>? selectedAnswers,
    int? remainingSeconds,
    QuizAttemptModel? result,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QuizAttemptState(
      status: status ?? this.status,
      attemptId: attemptId ?? this.attemptId,
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      result: result ?? this.result,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

String mapQuizError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية الوصول إلى هذا الاختبار';
  }
  if (error.isUnauthorized) {
    return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
  }
  if (error.statusCode == 404) {
    return 'الاختبار غير موجود';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message;
}

String mapQuizStartError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية الوصول إلى هذا الاختبار';
  }
  if (error.isValidationError) {
    final fieldErrors = error.fieldErrors;
    if (fieldErrors.isNotEmpty) {
      return fieldErrors.join('\n');
    }
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message.isNotEmpty ? error.message : 'تعذر بدء الاختبار';
}

String mapQuizSubmitError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية الوصول إلى هذا الاختبار';
  }
  if (error.isValidationError) {
    final fieldErrors = error.fieldErrors;
    if (fieldErrors.isNotEmpty) {
      return fieldErrors.join('\n');
    }
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message.isNotEmpty ? error.message : 'تعذر تسليم الاختبار';
}

class QuizzesListController extends StateNotifier<QuizzesListState> {
  QuizzesListController(this._repository) : super(const QuizzesListState());

  final QuizzesRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(
      status: FeatureLoadStatus.loading,
      clearError: true,
    );

    try {
      final quizzes = await _repository.getQuizzes();
      state = QuizzesListState(
        status: quizzes.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        quizzes: quizzes,
      );
    } on ApiException catch (error) {
      state = QuizzesListState(
        status: FeatureLoadStatus.error,
        errorMessage: mapQuizError(error),
      );
    } catch (_) {
      state = const QuizzesListState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  QuizModel? findById(int id) {
    for (final quiz in state.quizzes) {
      if (quiz.id == id) {
        return quiz;
      }
    }
    return null;
  }

  void upsertQuiz(QuizModel quiz) {
    final updated = [...state.quizzes];
    final index = updated.indexWhere((item) => item.id == quiz.id);
    if (index >= 0) {
      updated[index] = quiz;
    } else {
      updated.add(quiz);
    }

    state = state.copyWith(
      status: updated.isEmpty
          ? FeatureLoadStatus.empty
          : FeatureLoadStatus.loaded,
      quizzes: updated,
    );
  }
}

class QuizDetailsController extends StateNotifier<QuizDetailsState> {
  QuizDetailsController(this._repository) : super(const QuizDetailsState());

  final QuizzesRepository _repository;

  Future<void> load(int quizId, {QuizModel? cached}) async {
    if (cached != null) {
      state = QuizDetailsState(
        status: FeatureLoadStatus.loaded,
        quiz: cached,
      );
      return;
    }

    state = state.copyWith(
      status: FeatureLoadStatus.loading,
      clearError: true,
    );

    try {
      final quiz = await _repository.findQuizById(quizId);
      if (quiz == null) {
        state = const QuizDetailsState(
          status: FeatureLoadStatus.error,
          errorMessage: 'الاختبار غير موجود',
        );
        return;
      }

      state = QuizDetailsState(
        status: FeatureLoadStatus.loaded,
        quiz: quiz,
      );
    } on ApiException catch (error) {
      state = QuizDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapQuizError(error),
      );
    } catch (_) {
      state = const QuizDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }
}

class QuizAttemptController extends StateNotifier<QuizAttemptState> {
  QuizAttemptController(this._repository, this.quizId)
      : super(const QuizAttemptState());

  final QuizzesRepository _repository;
  final int quizId;

  Future<bool> start() async {
    state = state.copyWith(
      status: QuizAttemptStatus.loading,
      clearError: true,
    );

    try {
      final result = await _repository.startQuiz(quizId);
      final duration = result.quiz.durationMinutes;

      state = QuizAttemptState(
        status: QuizAttemptStatus.loaded,
        attemptId: result.attemptId,
        quiz: result.quiz,
        remainingSeconds:
            duration != null && duration > 0 ? duration * 60 : null,
      );
      return true;
    } on ApiException catch (error) {
      state = QuizAttemptState(
        status: QuizAttemptStatus.error,
        errorMessage: mapQuizStartError(error),
      );
    } catch (_) {
      state = const QuizAttemptState(
        status: QuizAttemptStatus.error,
        errorMessage: 'تعذر بدء الاختبار',
      );
    }
    return false;
  }

  void selectAnswer(int questionId, int answerId) {
    final updated = Map<int, int>.from(state.selectedAnswers);
    updated[questionId] = answerId;
    state = state.copyWith(selectedAnswers: updated);
  }

  void goToPreviousQuestion() {
    if (state.currentQuestionIndex <= 0) {
      return;
    }
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex - 1,
    );
  }

  void goToNextQuestion() {
    final questions = state.quiz?.questions ?? [];
    if (state.currentQuestionIndex >= questions.length - 1) {
      return;
    }
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
  }

  void tickTimer() {
    final remaining = state.remainingSeconds;
    if (remaining == null || remaining <= 0) {
      return;
    }
    state = state.copyWith(remainingSeconds: remaining - 1);
  }

  Future<QuizAttemptModel?> submit() async {
    if (state.status == QuizAttemptStatus.submitting) {
      return null;
    }

    state = state.copyWith(
      status: QuizAttemptStatus.submitting,
      clearError: true,
    );

    try {
      final result = await _repository.submitQuiz(
        quizId: quizId,
        questions: state.quiz?.questions ?? [],
        selectedAnswers: state.selectedAnswers,
      );

      state = QuizAttemptState(
        status: QuizAttemptStatus.submitted,
        attemptId: state.attemptId,
        quiz: state.quiz,
        selectedAnswers: state.selectedAnswers,
        remainingSeconds: state.remainingSeconds,
        result: result,
      );
      return result;
    } on ApiException catch (error) {
      state = QuizAttemptState(
        status: QuizAttemptStatus.error,
        attemptId: state.attemptId,
        quiz: state.quiz,
        selectedAnswers: state.selectedAnswers,
        currentQuestionIndex: state.currentQuestionIndex,
        remainingSeconds: state.remainingSeconds,
        errorMessage: mapQuizSubmitError(error),
      );
    } catch (_) {
      state = QuizAttemptState(
        status: QuizAttemptStatus.error,
        attemptId: state.attemptId,
        quiz: state.quiz,
        selectedAnswers: state.selectedAnswers,
        currentQuestionIndex: state.currentQuestionIndex,
        remainingSeconds: state.remainingSeconds,
        errorMessage: 'تعذر تسليم الاختبار',
      );
    }
    return null;
  }
}

final quizzesListControllerProvider =
    StateNotifierProvider<QuizzesListController, QuizzesListState>((ref) {
  return QuizzesListController(ref.watch(quizzesRepositoryProvider));
});

final quizDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<QuizDetailsController, QuizDetailsState, int>((ref, quizId) {
  return QuizDetailsController(ref.watch(quizzesRepositoryProvider));
});

final quizAttemptControllerProvider = StateNotifierProvider.autoDispose
    .family<QuizAttemptController, QuizAttemptState, int>((ref, quizId) {
  return QuizAttemptController(ref.watch(quizzesRepositoryProvider), quizId);
});
