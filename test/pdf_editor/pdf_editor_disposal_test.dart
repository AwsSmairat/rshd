import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/controllers/pdf_editor_controller.dart';
import 'package:rshd/features/pdf_editor/services/annotation_local_cache.dart';
import 'package:rshd/features/subjects/data/models/pdf_annotation_model.dart';
import 'package:rshd/features/subjects/data/subjects_repository.dart';

class _PendingSubjectsRepository implements SubjectsRepository {
  final requestStarted = Completer<void>();
  final response = Completer<PdfAnnotationModel>();

  @override
  Future<PdfAnnotationModel> getFileAnnotations(int fileId) {
    if (!requestStarted.isCompleted) {
      requestStarted.complete();
    }
    return response.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('late annotation response after dispose does not write state', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'rshd_pdf_editor_disposal_',
    );

    final repository = _PendingSubjectsRepository();

    final controller = PdfEditorController(
      repository,
      42,
      localCache: AnnotationLocalCache(
        userId: 1,
        documentsDirectoryProvider: () async => tempDir,
      ),
    );

    final loadFuture = controller.load();

    await repository.requestStarted.future;

    controller.dispose();

    repository.response.complete(
      const PdfAnnotationModel(fileId: 42, annotationJson: {}),
    );

    await expectLater(loadFuture, completes);

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });
}
