import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/subjects/data/models/lesson_file_model.dart';

void main() {
  test('unlocked Word files can be opened in the in-app viewer', () {
    const file = LessonFileModel(
      id: 1,
      lessonId: 2,
      title: 'test1.1',
      fileType: 'doc',
      requiresSignedDownload: true,
    );

    expect(file.canOpen, isTrue);
    expect(file.canViewInApp, isTrue);
  });

  test('locked Word files cannot be opened', () {
    const file = LessonFileModel(
      id: 1,
      lessonId: 2,
      title: 'test1.1',
      fileType: 'doc',
      isLocked: true,
      requiresSignedDownload: true,
    );

    expect(file.canViewInApp, isFalse);
  });
}
