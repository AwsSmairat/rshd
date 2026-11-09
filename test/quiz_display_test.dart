import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/l10n/content_direction.dart';
import 'package:rshd/core/theme/app_theme.dart';
import 'package:rshd/features/quizzes/data/models/quiz_answer_model.dart';
import 'package:rshd/features/quizzes/data/models/quiz_question_model.dart';
import 'package:rshd/features/quizzes/widgets/quiz_answer_option.dart';
import 'package:rshd/features/quizzes/widgets/quiz_question_card.dart';
import 'package:rshd/features/quizzes/widgets/quiz_text_cleanup.dart';

QuizQuestionModel _question(String text, List<String> answers) {
  return QuizQuestionModel(
    id: 1,
    quizId: 1,
    questionText: text,
    answers: [
      for (var i = 0; i < answers.length; i++)
        QuizAnswerModel(id: i + 10, questionId: 1, answerText: answers[i]),
    ],
  );
}

Future<void> _pump(WidgetTester tester, QuizQuestionModel question) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(
            child: QuizQuestionCard(
              question: question,
              questionNumber: 1,
              totalQuestions: 4,
              selectedAnswerId: 11,
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('content direction follows the first strong letter', () {
    expect(contentDirectionOf('1. The most important'), TextDirection.ltr);
    expect(contentDirectionOf('ما هو الجواب؟'), TextDirection.rtl);
    expect(contentDirectionOf('(a) α-helix'), TextDirection.ltr);
    expect(
      contentDirectionOf('123', fallback: TextDirection.ltr),
      TextDirection.ltr,
    );
  });

  test('labels the screen already shows are dropped', () {
    expect(
      QuizTextCleanup.question('1. The most important mechanism is:'),
      'The most important mechanism is:',
    );
    expect(QuizTextCleanup.options(['a) Anoxia.', 'b) Cerebral ischemia .']), [
      'Anoxia.',
      'Cerebral ischemia .',
    ]);
    // Only when every option is labelled.
    expect(QuizTextCleanup.options(['a) Anoxia', 'Bleeding']), [
      'a) Anoxia',
      'Bleeding',
    ]);
    expect(QuizTextCleanup.options(['أ) نعم', 'ب) لا']), ['نعم', 'لا']);
  });

  testWidgets('an English question reads left to right inside the Arabic app', (
    tester,
  ) async {
    await _pump(
      tester,
      _question(
        '1. The most important mechanism of death in ligature strangulation is:',
        ['a) Anoxia.', 'b) Cerebral ischemia.', 'c) Fracture', 'd) Edema'],
      ),
    );

    final questionText = find.text(
      'The most important mechanism of death in ligature strangulation is:',
    );
    expect(questionText, findsOneWidget);
    expect(Directionality.of(tester.element(questionText)), TextDirection.ltr);
    expect(find.text('Anoxia.'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    // The app's own label keeps the app's direction.
    expect(
      Directionality.of(tester.element(find.text('السؤال 1 من 4'))),
      TextDirection.rtl,
    );
    expect(
      tester
          .widgetList<QuizAnswerOption>(find.byType(QuizAnswerOption))
          .where((option) => option.isSelected),
      hasLength(1),
    );
  });

  testWidgets('an Arabic question keeps Arabic letters and direction', (
    tester,
  ) async {
    await _pump(tester, _question('ما عاصمة الأردن؟', ['عمّان', 'إربد']));

    expect(
      Directionality.of(tester.element(find.text('ما عاصمة الأردن؟'))),
      TextDirection.rtl,
    );
    expect(find.text('أ'), findsOneWidget);
    expect(find.text('ب'), findsOneWidget);
  });
}
