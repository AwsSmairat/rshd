import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/services/pdf_cache_service.dart';
import 'package:rshd/features/pdf_editor/services/pdf_viewer_source_loader.dart';
import 'package:rshd/features/subjects/data/models/file_download_model.dart';
import 'package:rshd/features/subjects/data/subjects_repository.dart';

import 'pdf_export_test_helpers.dart';

class _FakeDownloadRepository implements SubjectsRepository {
  _FakeDownloadRepository(this.onDownload);

  final Future<FileDownloadModel> Function(int fileId) onDownload;
  int downloadCalls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<FileDownloadModel> getFileDownloadUrl(int fileId) async {
    downloadCalls++;
    return onDownload(fileId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfViewerSourceLoader', () {
    late Directory tempRoot;
    late PdfCacheService cacheService;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('pdf_viewer_source_');
      cacheService = PdfCacheService(
        documentsDirectoryProvider: () async => tempRoot,
      );
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('uses cache without requesting signed URL', () async {
      const fileId = 11;
      final bytes = await createTestPdfBytes();
      await cacheService.save(fileId, bytes);

      final loader = PdfViewerSourceLoader(cacheService: cacheService);
      final loaded = await loader.load(
        fileId: fileId,
        allowNetwork: false,
      );

      expect(loaded, bytes);
      expect(await loader.hasCached(fileId), isTrue);
    });

    test('offline load fails when cache is missing', () async {
      final loader = PdfViewerSourceLoader(cacheService: cacheService);

      expect(
        () => loader.load(fileId: 99, allowNetwork: false),
        throwsA(isA<Exception>()),
      );
    });

    test('requests signed URL only when cache is missing', () async {
      const fileId = 12;
      final bytes = await createTestPdfBytes();
      await cacheService.save(fileId, bytes);

      final repo = _FakeDownloadRepository((_) async {
        return FileDownloadModel(
          url: 'https://cdn.example.test/files/pilot.pdf?token=abc&expires=9999999999',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
      });

      final loader = PdfViewerSourceLoader(cacheService: cacheService);
      await loader.load(fileId: fileId, repository: repo);

      expect(repo.downloadCalls, 0);
    });
  });
}
