import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:syncfusion_flutter_pdf/pdf.dart';

Future<Uint8List> createTestPdfBytes({int pageCount = 1}) async {
  final document = PdfDocument();
  for (var i = 0; i < pageCount; i++) {
    final page = document.pages.add();
    page.graphics.drawString(
      'Page ${i + 1}',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      bounds: const Rect.fromLTWH(72, 72, 400, 24),
    );
  }

  final bytes = Uint8List.fromList(await document.save());
  document.dispose();
  return bytes;
}

Map<String, dynamic> emptyAnnotationDocument({int? documentId}) {
  return {
    'version': 2,
    'document_id': ?documentId,
    'pages': <String, dynamic>{},
  };
}

Map<String, dynamic> annotationDocumentWith({
  required int pageNumber,
  required List<Map<String, dynamic>> annotations,
  double pageWidth = 595,
  double pageHeight = 842,
}) {
  return {
    'version': 2,
    'pages': {
      '$pageNumber': {
        'page_width': pageWidth,
        'page_height': pageHeight,
        'annotations': annotations,
      },
    },
  };
}

Map<String, dynamic> inkAnnotation({
  int pageNumber = 1,
  List<Map<String, double>> points = const [
    {'nx': 0.1, 'ny': 0.1},
    {'nx': 0.3, 'ny': 0.3},
  ],
  String color = '#0B1F3A',
}) {
  return {
    'id': 'ink-1',
    'type': 'ink',
    'pageNumber': pageNumber,
    'points': points,
    'color': color,
    'stroke_width': 0.004,
    'opacity': 1,
  };
}

Map<String, dynamic> highlightAnnotation({
  int pageNumber = 1,
  double x = 0.2,
  double y = 0.2,
  double width = 0.3,
  double height = 0.08,
}) {
  return {
    'id': 'highlight-1',
    'type': 'highlighter',
    'pageNumber': pageNumber,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'color': '#FFE066',
    'opacity': 0.35,
  };
}

Map<String, dynamic> textAnnotation({
  int pageNumber = 1,
  required String text,
  double x = 0.1,
  double y = 0.5,
}) {
  return {
    'id': 'text-1',
    'type': 'text',
    'pageNumber': pageNumber,
    'x': x,
    'y': y,
    'width': 0.4,
    'height': 0.1,
    'text': text,
    'color': '#0B1F3A',
    'font_size': 0.025,
  };
}

Map<String, dynamic> noteAnnotation({
  int pageNumber = 1,
  required String text,
}) {
  return {
    'id': 'note-1',
    'type': 'note',
    'pageNumber': pageNumber,
    'x': 0.15,
    'y': 0.15,
    'text': text,
  };
}

Map<String, dynamic> shapeAnnotation({
  int pageNumber = 1,
  String shape = 'rectangle',
}) {
  return {
    'id': 'shape-1',
    'type': 'shape',
    'pageNumber': pageNumber,
    'x': 0.4,
    'y': 0.4,
    'width': 0.2,
    'height': 0.15,
    'shape': shape,
    'stroke_color': '#0B1F3A',
    'stroke_width': 0.003,
  };
}

bool isValidPdfHeader(Uint8List bytes) {
  if (bytes.length < 5) return false;
  return String.fromCharCodes(bytes.sublist(0, 5)) == '%PDF-';
}

int readPdfPageCount(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  final count = document.pages.count;
  document.dispose();
  return count;
}
