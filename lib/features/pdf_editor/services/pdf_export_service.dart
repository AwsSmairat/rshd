import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/annotation_enums.dart';
import '../models/pdf_editor_models.dart';

typedef ExportProgressCallback = void Function(double progress, String message);

class PdfExportService {
  PdfExportService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<File> exportAnnotatedPdf({
    required String sourceUrl,
    required String originalFileName,
    required Map<String, dynamic> annotationJson,
    ExportProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.05, 'جاري تحميل الملف الأصلي...');
    final bytes = await _downloadPdf(sourceUrl);
    onProgress?.call(0.25, 'جاري دمج التعليقات...');

    final document = PdfDocument(inputBytes: bytes);
    final annotations = PdfAnnotationDocumentV2(annotationJson);

    var pageIndex = 0;
    for (var i = 0; i < document.pages.count; i++) {
      pageIndex = i + 1;
      final page = document.pages[i];
      final pageAnnotations = annotations.annotationsForPage(pageIndex);
      final pageWidth = page.size.width;
      final pageHeight = page.size.height;

      for (final annotation in pageAnnotations) {
        _drawAnnotation(page, annotation, pageWidth, pageHeight);
      }

      onProgress?.call(
        0.25 + (pageIndex / document.pages.count) * 0.65,
        'دمج الصفحة $pageIndex...',
      );
    }

    onProgress?.call(0.92, 'جاري حفظ النسخة...');
    final savedBytes = Uint8List.fromList(await document.save());
    document.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/pdf_exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }

    final baseName = originalFileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final output = File('${exportsDir.path}/$baseName-معدل.pdf');
    await output.writeAsBytes(savedBytes, flush: true);

    onProgress?.call(1, 'اكتمل التصدير');
    return output;
  }

  Future<Uint8List> _downloadPdf(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw Exception('تعذر تحميل ملف PDF');
    }
    return Uint8List.fromList(data);
  }

  void _drawAnnotation(
    PdfPage page,
    PdfEditorAnnotation annotation,
    double pageWidth,
    double pageHeight,
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
        _drawText(page, annotation, pageWidth, pageHeight);
      case AnnotationType.note:
        _drawNoteMarker(page, annotation, pageWidth, pageHeight);
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
  ) {
    final text = annotation.data['text']?.toString() ?? '';
    if (text.isEmpty) return;

    final fontSize =
        ((annotation.data['font_size'] as num?)?.toDouble() ?? 0.025) *
            pageWidth;
    final font = PdfStandardFont(PdfFontFamily.helvetica, fontSize);
    final brush = PdfSolidBrush(_parsePdfColor(annotation.data['color']?.toString()));

    page.graphics.drawString(
      text,
      font,
      brush: brush,
      bounds: Rect.fromLTWH(
        annotation.x * pageWidth,
        annotation.y * pageHeight,
        annotation.width * pageWidth,
        annotation.height * pageHeight,
      ),
      format: PdfStringFormat(
        textDirection: PdfTextDirection.rightToLeft,
        alignment: PdfTextAlignment.right,
      ),
    );
  }

  void _drawNoteMarker(
    PdfPage page,
    PdfEditorAnnotation annotation,
    double pageWidth,
    double pageHeight,
  ) {
    final x = annotation.x * pageWidth;
    final y = annotation.y * pageHeight;
    page.graphics.drawEllipse(
      Rect.fromCircle(center: Offset(x, y), radius: 8),
      pen: PdfPen(PdfColor(11, 31, 58), width: 1),
      brush: PdfSolidBrush(PdfColor(214, 181, 109)),
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
      case 'arrow':
        page.graphics.drawLine(pen, rect.topLeft, rect.bottomRight);
      case 'circle':
        page.graphics.drawEllipse(rect, pen: pen);
      default:
        page.graphics.drawRectangle(pen: pen, bounds: rect);
    }
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
