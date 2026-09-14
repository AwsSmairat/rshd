import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/security/protected_content_cache.dart';
import 'package:rshd/features/pdf_editor/services/annotation_local_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  Future<Directory> documentsDirectory() async => tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'rshd_annotation_cache_security_',
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('annotation and reading session cache is isolated per user', () async {
    final userOne = AnnotationLocalCache(
      userId: 11,
      documentsDirectoryProvider: documentsDirectory,
    );
    final userTwo = AnnotationLocalCache(
      userId: 22,
      documentsDirectoryProvider: documentsDirectory,
    );

    await userOne.saveAnnotations(7, {'owner': 11});
    await userTwo.saveAnnotations(7, {'owner': 22});

    await userOne.saveSession(
      7,
      const PdfReadingSession(pageNumber: 3, zoomLevel: 1.25),
    );
    await userTwo.saveSession(
      7,
      const PdfReadingSession(pageNumber: 9, zoomLevel: 2),
    );

    expect((await userOne.loadAnnotations(7))?['owner'], 11);
    expect((await userTwo.loadAnnotations(7))?['owner'], 22);

    expect((await userOne.loadSession(7))?.pageNumber, 3);
    expect((await userTwo.loadSession(7))?.pageNumber, 9);

    expect(
      File('${tempDir.path}/pdf_annotations/11/7.json').existsSync(),
      isTrue,
    );
    expect(
      File('${tempDir.path}/pdf_annotations/22/7.json').existsSync(),
      isTrue,
    );
  });

  test(
    'clearForUser removes only the selected user PDF editor cache',
    () async {
      final userOne = AnnotationLocalCache(
        userId: 11,
        documentsDirectoryProvider: documentsDirectory,
      );
      final userTwo = AnnotationLocalCache(
        userId: 22,
        documentsDirectoryProvider: documentsDirectory,
      );

      await userOne.saveAnnotations(7, {'owner': 11});
      await userTwo.saveAnnotations(7, {'owner': 22});

      await userOne.saveSession(
        7,
        const PdfReadingSession(pageNumber: 4, zoomLevel: 1),
      );
      await userTwo.saveSession(
        7,
        const PdfReadingSession(pageNumber: 8, zoomLevel: 1.5),
      );

      await ProtectedContentCache.clearForUser(
        11,
        documentsDirectoryProvider: documentsDirectory,
      );

      expect(await userOne.loadAnnotations(7), isNull);
      expect(await userOne.loadSession(7), isNull);

      expect((await userTwo.loadAnnotations(7))?['owner'], 22);
      expect((await userTwo.loadSession(7))?.pageNumber, 8);
    },
  );
}
