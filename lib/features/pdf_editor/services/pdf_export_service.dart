import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/annotation_enums.dart';
import '../models/pdf_editor_models.dart';
import 'pdf_arabic_font_loader.dart';
import 'pdf_cache_service.dart';
import 'pdf_export_filename.dart';

typedef ExportProgressCallback = void Function(double progress, String message);

class PdfExportResult {
  const PdfExportResult({
    required this.file,
    required this.fileName,
    required this.pageCount,
  });

  final File file;
  final String fileName;
  final int pageCount;
}

class PdfExportService {
  PdfExportService({
    PdfCacheService? cacheService,
    PdfArabicFontLoader? fontLoader,
    Future<Directory> Function()? tempDirectoryProvider,
  })  : _cacheService = cacheService ?? PdfCacheService(),
        _fontLoader = fontLoader ?? PdfArabicFontLoader(),
        _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory;

  final PdfCacheService _cacheService;
  final PdfArabicFontLoader _fontLoader;
  final Future<Directory> Function() _tempDirectoryProvider;

  static const _exportRetention = Duration(hours: 24);

  Future<PdfExportResult> exportAnnotatedPdf({
    required Map<String, dynamic> annotationJson,
    required String documentTitle,
    String? courseTitle,
    String? sourceUrl,
    Uint8List? sourceBytes,
    int? fileId,
    bool allowNetwork = true,
    ExportProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.05, 'جاري تجهيز الملف...');

    final bytes = await _resolveSourceBytes(
      sourceBytes: sourceBytes,
      fileId: fileId,
      sourceUrl: sourceUrl,
      allowNetwork: allowNetwork,
      onProgress: onProgress,
    );

    onProgress?.call(0.25, 'جاري دمج التعليقات...');
    final fontBytes = await _fontLoader.loadFontBytes();

    final document = PdfDocument(inputBytes: bytes);
    final annotations = PdfAnnotationDocumentV2(annotationJson);

    for (var i = 0; i < document.pages.count; i++) {
      final pageIndex = i + 1;
      final page = document.pages[i];
      final pageAnnotations = annotations.annotationsForPage(pageIndex);
      final pageWidth = page.size.width;
      final pageHeight = page.size.height;

      for (final annotation in pageAnnotations) {
        _drawAnnotation(
          page,
          annotation,
          pageWidth,
          pageHeight,
          fontBytes,
        );
      }

      onProgress?.call(
        0.25 + (pageIndex / document.pages.count) * 0.65,
        'دمج الصفحة $pageIndex...',
      );
    }

    onProgress?.call(0.92, 'جاري حفظ النسخة...');
    final savedBytes = Uint8List.fromList(await document.save());
    final pageCount = document.pages.count;
    document.dispose();

    final fileName = PdfExportFilename.build(
      courseTitle: courseTitle,
      documentTitle: documentTitle,
    );
    final outputFile = await _writeTempExport(fileName, savedBytes);

    onProgress?.call(1, 'اكتمل التصدير');
    return PdfExportResult(
      file: outputFile,
      fileName: fileName,
      pageCount: pageCount,
    );
  }

  Future<Uint8List> _resolveSourceBytes({
    Uint8List? sourceBytes,
    int? fileId,
    String? sourceUrl,
    required bool allowNetwork,
    ExportProgressCallback? onProgress,
  }) async {
    if (sourceBytes != null && sourceBytes.isNotEmpty) {
      if (fileId != null) {
        await _cacheService.save(fileId, sourceBytes);
      }
      return sourceBytes;
    }

    if (fileId != null) {
      onProgress?.call(0.1, 'جاري تحميل الملف...');
      return _cacheService.resolveBytes(
        fileId: fileId,
        sourceUrl: sourceUrl,
        allowNetwork: allowNetwork,
      );
    }

    if (sourceUrl == null || sourceUrl.trim().isEmpty) {
      throw Exception('مصدر ملف PDF غير متوفر');
    }

    onProgress?.call(0.1, 'جاري تحميل الملف...');
    return _cacheService.cacheFromUrl(-1, sourceUrl);
  }

  Future<File> _writeTempExport(String fileName, Uint8List bytes) async {
    final tempDir = await _tempDirectoryProvider();
    final exportsDir = Directory('${tempDir.path}/pdf_exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }

    await _cleanupOldExports(exportsDir);

    final output = File('${exportsDir.path}/$fileName');
    await output.writeAsBytes(bytes, flush: true);
    return output;
  }

  Future<void> _cleanupOldExports(Directory exportsDir) async {
    final cutoff = DateTime.now().subtract(_exportRetention);
    if (!await exportsDir.exists()) return;

    await for (final entity in exportsDir.list()) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.pdf')) continue;

      try {
        final modified = await entity.lastModified();
        if (modified.isBefore(cutoff)) {
          await entity.delete();
        }
      } catch (_) {}
    }
  }

  void _drawAnnotation(
    PdfPage page,
    PdfEditorAnnotation annotation,
    double pageWidth,
    double pageHeight,
    Uint8List fontBytes,
  ) {
    switch (annotation.type) {
      case AnnotationType.ink:
        _drawInk(page, annotation, pageWidth, pageHeight);
      case AnnotationType.highlighter:
        if (annotation.width > 0 && annotation.height > 0) {
          _drawHighlightRect(page, annotation, pageWidth, pageHeight);
        } else {
          _drawInk(page, annotation, pageWidth, pageHeight);
        }
      case AnnotationType.text:
        _drawText(page, annotation, pageWidth, pageHeight, fontBytes);
      case AnnotationType.note:
        _drawNote(page, annotation, pageWidth, pageHeight, fontBytes);
      case AnnotationType.shape:
        _drawShape(page, annotation, pageWidth, pageHeight);
      case AnnotationType.image:
        break;
    }
  }

  void _drawInk(
    PdfPage page,
    PdfEditorAnnotation annotation,
    double pageWidth,
    double pageHeight,
  ) {
    final rawPoints = annotation.data['points'];
    if (rawPoints is! List || rawPoints.length < 2) return;

    final points = rawPoints
        .whereType<Map>()
        .map((entry) => NormalizedPoint.fromJson(Map<String, dynamic>.from(entry)))
        .map((p) => Offset(p.nx * pageWidth, p.ny * pageHeight))
        .toList();

    final opacity = ((annotation.data['opacity'] as num?)?.toDouble() ?? 1) * 255;
    final color = _parsePdfColor(
      annotation.data['color']?.toString(),
      opacity: opacity.toInt(),
    );
    final strokeWidth =
        ((annotation.data['stroke_width'] as num?)?.toDouble() ?? 0.004) *
            pageWidth;

    final pen = PdfPen(color, width: strokeWidth);

    for (var i = 1; i < points.length; i++) {
      page.graphics.drawLine(pen, points[i - 1], points[i]);
    }
  }

  void _drawHighlightRect(
    PdfPage page,
    PdfEditorAnnotation annotation,
    double pageWidth,
    double pageHeight,
  ) {
    final opacity = ((annotation.data['opacity'] as num?)?.toDouble() ?? 0.35) * 255;
    final brush = PdfSolidBrush(
      _parsePdfColor(
        annotation.data['color']?.toString(),
        opacity: opacity.toInt(),
      ),
    );
    page.graphics.drawRectangle(
      brush: brush,
      bounds: Rect.fromLTWH(
        annotation.x * pageWidth,
        annotation.y * pageHeight,
        annotation.width * pageWidth,
        annotation.height * pageHeight,
      ),
    );
  }

  void _drawText(
    PdfPage page,
    PdfEditorAnnotation annotation,
    double pageWidth,
    double pageHeight,
    Uint8List fontBytes,
  ) {
    final text = annotation.data['text']?.toString() ?? '';
    if (text.isEmpty) return;

    final fontSize =
        ((annotation.data['font_size'] as num?)?.toDouble() ?? 0.025) *
            pageWidth;
    final font = _fontLoader.createFontFromBytes(fontBytes, fontSize);
    final brush = PdfSolidBrush(_parsePdfColor(annotation.data['color']?.toString()));

    page.graphics.drawString(
      text,
      font,
      brush: brush,
      bounds: Rect.fromLTWH(
        annotation.x * pageWidth,
        annotation.y * pageHeight,
        annotation.width > 0 ? annotation.width * pageWidth : pageWidth * 0.4,
        annotation.height > 0 ? annotation.height * pageHeight : pageHeight * 0.12,
      ),
      format: PdfArabicFontLoader.textFormat(text),
    );
  }

  void _drawNote(
    PdfPage page,
    PdfEditorAnnotation annotation,
    double pageWidth,
    double pageHeight,
    Uint8List fontBytes,
  ) {
    final x = annotation.x * pageWidth;
    final y = annotation.y * pageHeight;

    page.graphics.drawEllipse(
      Rect.fromCircle(center: Offset(x, y), radius: 8),
      pen: PdfPen(PdfColor(11, 31, 58), width: 1),
      brush: PdfSolidBrush(PdfColor(214, 181, 109)),
    );

    final text = annotation.data['text']?.toString() ?? '';
    if (text.isEmpty) return;

    final fontSize = 0.018 * pageWidth;
    final font = _fontLoader.createFontFromBytes(fontBytes, fontSize);
    final textBounds = Rect.fromLTWH(
      (x + 12).clamp(0, pageWidth - 8),
      (y - 6).clamp(0, pageHeight - 8),
      math.min(pageWidth * 0.35, pageWidth - x - 12),
      math.min(pageHeight * 0.18, pageHeight - y),
    );

    page.graphics.drawRectangle(
      pen: PdfPen(PdfColor(214, 181, 109), width: 0.8),
      brush: PdfSolidBrush(PdfColor(255, 252, 245)),
      bounds: textBounds,
    );
    page.graphics.drawString(
      text,
      font,
      brush: PdfSolidBrush(PdfColor(11, 31, 58)),
      bounds: textBounds.inflate(-4),
      format: PdfArabicFontLoader.textFormat(text),
    );
  }

  void _drawShape(
    PdfPage page,
    PdfEditorAnnotation annotation,
    double pageWidth,
    double pageHeight,
  ) {
    final rect = Rect.fromLTWH(
      annotation.x * pageWidth,
      annotation.y * pageHeight,
      annotation.width * pageWidth,
      annotation.height * pageHeight,
    );
    final pen = PdfPen(
      _parsePdfColor(annotation.data['stroke_color']?.toString()),
      width: ((annotation.data['stroke_width'] as num?)?.toDouble() ?? 0.003) *
          pageWidth,
    );

    switch (annotation.data['shape']?.toString()) {
      case 'line':
        page.graphics.drawLine(pen, rect.topLeft, rect.bottomRight);
      case 'arrow':
        _drawArrow(page, rect.topLeft, rect.bottomRight, pen);
      case 'circle':
        page.graphics.drawEllipse(rect, pen: pen);
      default:
        page.graphics.drawRectangle(pen: pen, bounds: rect);
    }
  }

  void _drawArrow(PdfPage page, Offset start, Offset end, PdfPen pen) {
    page.graphics.drawLine(pen, start, end);

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const headLength = 12.0;
    const headAngle = math.pi / 6;

    final pointOne = Offset(
      end.dx - headLength * math.cos(angle - headAngle),
      end.dy - headLength * math.sin(angle - headAngle),
    );
    final pointTwo = Offset(
      end.dx - headLength * math.cos(angle + headAngle),
      end.dy - headLength * math.sin(angle + headAngle),
    );

    page.graphics.drawLine(pen, end, pointOne);
    page.graphics.drawLine(pen, end, pointTwo);
  }

  PdfColor _parsePdfColor(String? hex, {int opacity = 255}) {
    if (hex == null || hex.isEmpty) return PdfColor(11, 31, 58, opacity);
    final value = hex.replaceAll('#', '');
    if (value.length == 6) {
      final parsed = int.tryParse('FF$value', radix: 16);
      if (parsed != null) {
        return PdfColor(
          (parsed >> 16) & 0xFF,
          (parsed >> 8) & 0xFF,
          parsed & 0xFF,
          opacity,
        );
      }
    }
    return PdfColor(11, 31, 58, opacity);
  }
}
