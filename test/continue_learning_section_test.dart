import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/theme/app_theme.dart';
import 'package:rshd/features/home/widgets/continue_learning_card.dart';

void main() {
  testWidgets('with no enrolled course, invites the student to browse', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ContinueLearningSection(
            subjects: const [],
            progressFor: (_) => 0,
          ),
        ),
      ),
    );

    expect(find.text('ابدأ رحلتك التعليمية'), findsOneWidget);
    expect(find.text('تصفّح المواد'), findsOneWidget);
  });
}
