import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/services/pdf_arabic_font_loader.dart';
import 'package:rshd/features/pdf_editor/services/pdf_cache_service.dart';
import 'package:rshd/features/pdf_editor/services/pdf_export_service.dart';

import 'pdf_export_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late PdfArabicFontLoader fontLoader;
  late Uint8List fontBytes;

  setUpAll(() async {
    fontLoader = PdfArabicFontLoader();
    fontBytes = await fontLoader.loadFontBytes();
    expect(fontBytes, isNotEmpty);
  });

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('pdf_export_test_');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  PdfExportService createService({PdfCacheService? cacheService}) {
    return PdfExportService(
      cacheService: cacheService,
      fontLoader: fontLoader,
      tempDirectoryProvider: () async => tempRoot,
    );
  }

  group('PdfExportService', () {
    test('exports PDF without annotations', () async {
      final source = await createTestPdfBytes();
      final service = createService();

      final result = await service.exportAnnotatedPdf(
        sourceBytes: source,
        documentTitle: 'Blank',
        annotationJson: emptyAnnotationDocument(),
      );

      expect(await result.file.exists(), isTrue);
      final exported = await result.file.readAsBytes();
      expect(isValidPdfHeader(exported), isTrue);
      expect(readPdfPageCount(exported), 1);
      expect(result.pageCount, 1);
    });

    test('exports drawing ink annotation', () async {
      final source = await createTestPdfBytes();
      final service = createService();

      final result = await service.exportAnnotatedPdf(
        sourceBytes: source,
        documentTitle: 'Drawing',
        annotationJson: annotationDocumentWith(
          pageNumber: 1,
          annotations: [inkAnnotation()],
        ),
      );

      final exported = await result.file.readAsBytes();
      expect(isValidPdfHeader(exported), isTrue);
      expect(exported.length, greaterThan(source.length));
    });

    test('exports highlight annotation', () async {
      final source = await createTestPdfBytes();
      final service = createService();

      final result = await service.exportAnnotatedPdf(
        sourceBytes: source,
        documentTitle: 'Highlight',
        annotationJson: annotationDocumentWith(
          pageNumber: 1,
          annotations: [highlightAnnotation()],
        ),
      );

      expect(isValidPdfHeader(await result.file.readAsBytes()), isTrue);
    });

    test('exports English text annotation', () async {
      final source = await createTestPdfBytes();
      final service = createService();

      final result = await service.exportAnnotatedPdf(
        sourceBytes: source,
        documentTitle: 'English',
        annotationJson: annotationDocumentWith(
          pageNumber: 1,
          annotations: [textAnnotation(text: 'Hello World 123')],
        ),
      );

      final exported = await result.file.readAsBytes();
      expect(isValidPdfHeader(exported), isTrue);
      expect(String.fromCharCodes(exported), contains('NotoNaskh'));
    });

    test('exports Arabic text annotation with embedded font', () async {
      final source = await createTestPdfBytes();
      final service = createService();

      final result = await service.exportAnnotatedPdf(
        sourceBytes: source,
        documentTitle: 'Arabic',
        annotationJson: annotationDocumentWith(
          pageNumber: 1,
          annotations: [textAnnotation(text: 'مرحباً بالعالم')],
        ),
      );

      final exported = await result.file.readAsBytes();
      expect(isValidPdfHeader(exported), isTrue);
      expect(String.fromCharCodes(exported), contains('NotoNaskh'));
    });

    test('exports mixed Arabic and English text', () async {
      final source = await createTestPdfBytes();
      final service = createService();

      final result = await service.exportAnnotatedPdf(
        sourceBytes: source,
        documentTitle: 'Mixed',
        annotationJson: annotationDocumentWith(
          pageNumber: 1,
          annotations: [
            textAnnotation(text: 'Hello مرحباً 2026'),
            noteAnnotation(text: 'Note: ملاحظة'),
          ],
        ),
      );

      expect(isValidPdfHeader(await result.file.readAsBytes()), isTrue);
    });

    test('exports multipage PDF preserving page count', () async {
      final source = await createTestPdfBytes(pageCount: 3);
      final service = createService();

      final result = await service.exportAnnotatedPdf(
        sourceBytes: source,
        documentTitle: 'Multipage',
        annotationJson: annotationDocumentWith(
          pageNumber: 2,
          annotations: [highlightAnnotation(pageNumber: 2)],
        ),
      );

      expect(result.pageCount, 3);
      expect(readPdfPageCount(await result.file.readAsBytes()), 3);
    });

    test('exports shape annotations', () async {
      final source = await createTestPdfBytes();
      final service = createService();

      for (final shape in ['rectangle', 'circle', 'line', 'arrow']) {
        final result = await service.exportAnnotatedPdf(
          sourceBytes: source,
          documentTitle: 'Shape $shape',
          annotationJson: annotationDocumentWith(
            pageNumber: 1,
            annotations: [shapeAnnotation(shape: shape)],
          ),
        );

        expect(await result.file.exists(), isTrue);
        expect(isValidPdfHeader(await result.file.readAsBytes()), isTrue);
      }
    });

    test('exports offline from cached PDF bytes', () async {
      final source = await createTestPdfBytes();
      final cacheRoot = await Directory.systemTemp.createTemp(
        'pdf_cache_offline_',
      );
      final cacheService = PdfCacheService(
        documentsDirectoryProvider: () async => cacheRoot,
      );

      const fileId = 42;
      await cacheService.save(fileId, source);

      final service = createService(cacheService: cacheService);
      final result = await service.exportAnnotatedPdf(
        fileId: fileId,
        documentTitle: 'Offline',
        allowNetwork: false,
        annotationJson: annotationDocumentWith(
          pageNumber: 1,
          annotations: [inkAnnotation()],
        ),
      );

      expect(await result.file.exists(), isTrue);
      expect(isValidPdfHeader(await result.file.readAsBytes()), isTrue);

      await cacheRoot.delete(recursive: true);
    });

    test('cleans up old temporary exports', () async {
      final exportsDir = Directory('${tempRoot.path}/pdf_exports');
      await exportsDir.create(recursive: true);

      final staleFile = File('${exportsDir.path}/stale.pdf');
      await staleFile.writeAsBytes(await createTestPdfBytes());
      final staleTime = DateTime.now().subtract(const Duration(days: 2));
      await staleFile.setLastModified(staleTime);

      final service = createService();
      await service.exportAnnotatedPdf(
        sourceBytes: await createTestPdfBytes(),
        documentTitle: 'Cleanup',
        annotationJson: emptyAnnotationDocument(),
      );

      expect(await staleFile.exists(), isFalse);
      expect(await exportsDir.list().length, 1);
    });
  });

  group('PdfArabicFontLoader', () {
    test('detects Arabic characters', () {
      expect(PdfArabicFontLoader.containsArabic('مرحبا'), isTrue);
      expect(PdfArabicFontLoader.containsArabic('Hello'), isFalse);
      expect(PdfArabicFontLoader.containsArabic('Hello مرحبا'), isTrue);
    });

    test('loads bundled font bytes from assets', () async {
      final bytes = await rootBundle.load(PdfArabicFontLoader().assetPath);
      expect(bytes.lengthInBytes, greaterThan(1000));
    });
  });
}
