import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/network/api_exception.dart';
import 'package:rshd/features/quizzes/data/models/quiz_attempt_model.dart';
import 'package:rshd/features/quizzes/data/models/quiz_model.dart';
import 'package:rshd/features/quizzes/data/models/quiz_question_model.dart';
import 'package:rshd/features/quizzes/data/quizzes_repository.dart';
import 'package:rshd/features/quizzes/presentation/quizzes_controller.dart';

class _FailingSubmitRepository implements QuizzesRepository {
  _FailingSubmitRepository(this._error);

  final Object _error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<QuizAttemptModel> submitQuiz({
    required int quizId,
    required List<QuizQuestionModel> questions,
    required Map<int, int> selectedAnswers,
  }) async {
    throw _error;
  }
}

void main() {
  const quiz = QuizModel(id: 7, subjectId: 1, title: 'اختبار');

  QuizAttemptController controllerWith(Object error) {
    final controller = QuizAttemptController(
      _FailingSubmitRepository(error),
      quiz.id,
    );
    controller.state = const QuizAttemptState(
      status: QuizAttemptStatus.loaded,
      attemptId: 99,
      quiz: quiz,
      selectedAnswers: {1: 10, 2: 20},
      currentQuestionIndex: 1,
      remainingSeconds: 300,
    );
    return controller;
  }

  test('failed submit keeps the attempt loaded instead of erroring out', () async {
    final controller = controllerWith(
      ApiException(message: 'Network down', statusCode: 500),
    );

    final result = await controller.submit();

    expect(result, isNull);
    // An `error` status would swap the questions for the "start quiz" screen,
    // whose retry discards the attempt.
    expect(controller.state.status, QuizAttemptStatus.loaded);
    expect(controller.state.errorMessage, isNotNull);
  });

  test('failed submit preserves answers, attempt id and progress', () async {
    final controller = controllerWith(Exception('boom'));

    await controller.submit();

    expect(controller.state.attemptId, 99);
    expect(controller.state.quiz, quiz);
    expect(controller.state.selectedAnswers, {1: 10, 2: 20});
    expect(controller.state.currentQuestionIndex, 1);
    expect(controller.state.remainingSeconds, 300);
  });

  test('the attempt can be re-submitted after a failure', () async {
    final controller = controllerWith(Exception('boom'));

    await controller.submit();
    // The guard only blocks while `submitting`, so a retry must get through.
    final second = await controller.submit();

    expect(second, isNull);
    expect(controller.state.status, QuizAttemptStatus.loaded);
  });
}
