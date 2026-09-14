import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/announcements/data/announcements_repository.dart';
import 'package:rshd/features/announcements/presentation/announcements_controller.dart';
import 'package:rshd/features/assignments/data/assignments_repository.dart';
import 'package:rshd/features/assignments/presentation/assignments_controller.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/presentation/password_reset_controller.dart';
import 'package:rshd/features/grades/data/grades_repository.dart';
import 'package:rshd/features/grades/presentation/grades_controller.dart';
import 'package:rshd/features/quizzes/data/quizzes_repository.dart';
import 'package:rshd/features/quizzes/presentation/quizzes_controller.dart';
import 'package:rshd/features/subjects/data/subjects_repository.dart';
import 'package:rshd/features/subjects/presentation/subjects_controller.dart';

class _LateFailureRepository
    implements
        GradesRepository,
        AssignmentsRepository,
        AnnouncementsRepository,
        SubjectsRepository,
        QuizzesRepository,
        AuthRepository {
  final requestStarted = Completer<void>();
  final response = Completer<Never>();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (!requestStarted.isCompleted) {
      requestStarted.complete();
    }
    return response.future;
  }

  void fail() {
    if (!response.isCompleted) {
      response.completeError(StateError('late failure'));
    }
  }
}

Future<void> _expectLateFailureIgnored({
  required _LateFailureRepository repository,
  required Future<dynamic> operation,
  required void Function() dispose,
}) async {
  await repository.requestStarted.future;
  dispose();
  repository.fail();
  await expectLater(operation, completes);
}

void main() {
  group('autoDispose controllers ignore late async failures', () {
    test('GradeDetailsController', () async {
      final repository = _LateFailureRepository();
      final controller = GradeDetailsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.load(1),
        dispose: controller.dispose,
      );
    });

    test('AssignmentDetailsController', () async {
      final repository = _LateFailureRepository();
      final controller = AssignmentDetailsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.load(1),
        dispose: controller.dispose,
      );
    });

    test('AssignmentSubmitController', () async {
      final repository = _LateFailureRepository();
      final controller = AssignmentSubmitController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.submit(assignmentId: 1),
        dispose: controller.dispose,
      );
    });

    test('AnnouncementDetailsController', () async {
      final repository = _LateFailureRepository();
      final controller = AnnouncementDetailsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.load(1),
        dispose: controller.dispose,
      );
    });

    test('SubjectDetailsController', () async {
      final repository = _LateFailureRepository();
      final controller = SubjectDetailsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.load(1),
        dispose: controller.dispose,
      );
    });

    test('SubjectLessonsController', () async {
      final repository = _LateFailureRepository();
      final controller = SubjectLessonsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.load(1),
        dispose: controller.dispose,
      );
    });

    test('LessonDetailsController', () async {
      final repository = _LateFailureRepository();
      final controller = LessonDetailsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.load(1),
        dispose: controller.dispose,
      );
    });

    test('VideoDetailsController.load', () async {
      final repository = _LateFailureRepository();
      final controller = VideoDetailsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.load(1),
        dispose: controller.dispose,
      );
    });

    test('VideoDetailsController.refreshPlayback', () async {
      final repository = _LateFailureRepository();
      final controller = VideoDetailsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.refreshPlayback(1),
        dispose: controller.dispose,
      );
    });

    test('FileDetailsController', () async {
      final repository = _LateFailureRepository();
      final controller = FileDetailsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.load(1),
        dispose: controller.dispose,
      );
    });

    test('QuizDetailsController', () async {
      final repository = _LateFailureRepository();
      final controller = QuizDetailsController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.load(1),
        dispose: controller.dispose,
      );
    });

    test('QuizAttemptController.start', () async {
      final repository = _LateFailureRepository();
      final controller = QuizAttemptController(repository, 1);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.start(),
        dispose: controller.dispose,
      );
    });

    test('QuizAttemptController.submit', () async {
      final repository = _LateFailureRepository();
      final controller = QuizAttemptController(repository, 1);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.submit(),
        dispose: controller.dispose,
      );
    });

    test('PasswordResetController.requestReset', () async {
      final repository = _LateFailureRepository();
      final controller = PasswordResetController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.requestReset('student@example.com'),
        dispose: controller.dispose,
      );
    });

    test('PasswordResetController.verifyCode', () async {
      final repository = _LateFailureRepository();
      final controller = PasswordResetController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.verifyCode(
          email: 'student@example.com',
          code: '123456',
        ),
        dispose: controller.dispose,
      );
    });

    test('PasswordResetController.resendCode', () async {
      final repository = _LateFailureRepository();
      final controller = PasswordResetController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.resendCode('student@example.com'),
        dispose: controller.dispose,
      );
    });

    test('PasswordResetController.resetPassword', () async {
      final repository = _LateFailureRepository();
      final controller = PasswordResetController(repository);

      await _expectLateFailureIgnored(
        repository: repository,
        operation: controller.resetPassword(
          email: 'student@example.com',
          resetToken: 'reset-token',
          password: 'Password123!',
          passwordConfirmation: 'Password123!',
        ),
        dispose: controller.dispose,
      );
    });
  });
}
