import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/services/pdf_cache_service.dart';
import 'package:rshd/features/pdf_editor/services/pdf_share_service.dart';

import 'pdf_export_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfCacheService', () {
    late Directory cacheRoot;
    late PdfCacheService cacheService;

    setUp(() async {
      cacheRoot = await Directory.systemTemp.createTemp('pdf_cache_service_');
      cacheService = PdfCacheService(
        documentsDirectoryProvider: () async => cacheRoot,
      );
    });

    tearDown(() async {
      if (await cacheRoot.exists()) {
        await cacheRoot.delete(recursive: true);
      }
    });

    test('saves and reads cached PDF bytes', () async {
      const fileId = 7;
      final bytes = await createTestPdfBytes();

      await cacheService.save(fileId, bytes);

      expect(await cacheService.hasCached(fileId), isTrue);
      expect(await cacheService.readCached(fileId), bytes);
    });

    test('resolveBytes uses cache without network', () async {
      const fileId = 9;
      final bytes = await createTestPdfBytes();
      await cacheService.save(fileId, bytes);

      final resolved = await cacheService.resolveBytes(
        fileId: fileId,
        allowNetwork: false,
      );

      expect(resolved, bytes);
    });
  });

  group('PdfShareService', () {
    test('throws when exported file is missing', () async {
      final service = PdfShareService();
      final missing = File('${Directory.systemTemp.path}/missing_export.pdf');

      expect(
        () => service.shareExportedPdf(file: missing),
        throwsA(isA<Exception>()),
      );
    });

    test('accepts existing exported PDF file', () async {
      final tempDir = await Directory.systemTemp.createTemp('pdf_share_test_');
      final file = File('${tempDir.path}/sample.pdf');
      await file.writeAsBytes(await createTestPdfBytes());

      final service = PdfShareService();
      expect(await file.exists(), isTrue);
      expect(file.path.endsWith('.pdf'), isTrue);
      expect(service, isA<PdfShareService>());

      await tempDir.delete(recursive: true);
    });
  });
}
