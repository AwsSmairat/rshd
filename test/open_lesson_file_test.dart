import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rshd/features/subjects/data/models/lesson_file_model.dart';
import 'package:rshd/features/subjects/utils/open_lesson_file.dart';

void main() {
  Future<void> tapOpen(WidgetTester tester, LessonFileModel file) async {
    final router = GoRouter(
      initialLocation: '/lesson',
      routes: [
        GoRoute(
          path: '/lesson',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => openLessonFile(context, file),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(path: '/files/:id', builder: (_, _) => const Text('details')),
        GoRoute(
          path: '/files/:id/pdf',
          builder: (_, _) => const Text('viewer'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a viewable file opens straight in the viewer', (tester) async {
    const file = LessonFileModel(
      id: 37,
      lessonId: 1,
      title: 'Lecture 1',
      fileType: 'pdf',
      requiresSignedDownload: true,
    );
    await tapOpen(tester, file);
    expect(find.text('viewer'), findsOneWidget);
    expect(find.text('details'), findsNothing);
  });

  testWidgets('a file not ready to view goes to its page', (tester) async {
    const file = LessonFileModel(id: 38, lessonId: 1, title: 'Notes');
    await tapOpen(tester, file);
    expect(find.text('details'), findsOneWidget);
  });

  testWidgets('a locked file stays put and says so', (tester) async {
    const file = LessonFileModel(
      id: 39,
      lessonId: 1,
      title: 'Locked',
      fileType: 'pdf',
      isLocked: true,
    );
    await tapOpen(tester, file);
    expect(find.text('open'), findsOneWidget);
    expect(find.text('الملف مقفل. فعّل المادة لفتحه.'), findsOneWidget);
  });
}
