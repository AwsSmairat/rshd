import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../pdf_editor/services/pdf_arabic_font_loader.dart';
import 'office_document_html_converter.dart';

class OfficeDocumentPdfConverter {
  OfficeDocumentPdfConverter({PdfArabicFontLoader? fontLoader})
    : _fontLoader = fontLoader ?? PdfArabicFontLoader();

  final PdfArabicFontLoader _fontLoader;

  /// Unzipping the document and laying out the PDF are both CPU-bound and used
  /// to freeze the UI while a Word file opened, so they run on a background
  /// isolate. The font is read here because assets need the root isolate.
  Future<Uint8List> convert(Uint8List bytes) async {
    final fontBytes = await _fontLoader.loadFontBytes();
    return compute(
      _renderOfficeDocumentToPdf,
      _OfficePdfRequest(documentBytes: bytes, fontBytes: fontBytes),
    );
  }
}

@immutable
class _OfficePdfRequest {
  const _OfficePdfRequest({
    required this.documentBytes,
    required this.fontBytes,
  });

  final Uint8List documentBytes;
  final Uint8List fontBytes;
}

Future<Uint8List> _renderOfficeDocumentToPdf(_OfficePdfRequest request) async {
  const contentConverter = OfficeDocumentHtmlConverter();
  final paragraphs = contentConverter.extractParagraphs(request.documentBytes);
  if (paragraphs.isEmpty) {
    throw const FormatException('لا يمكن قراءة محتوى الملف');
  }

  final font = PdfTrueTypeFont(request.fontBytes, 13);
  final document = PdfDocument();
  document.pageSettings.size = PdfPageSize.a4;
  document.pageSettings.margins.all = 0;

  const margin = 48.0;
  var page = document.pages.add();
  var y = margin;
  final pageWidth = page.size.width;
  final pageHeight = page.size.height;
  final contentWidth = pageWidth - (margin * 2);

  for (final paragraph in paragraphs) {
    final format = PdfArabicFontLoader.textFormat(paragraph);
    format.lineSpacing = 6;
    final measured = font.measureString(
      paragraph,
      format: format,
      layoutArea: Size(contentWidth, pageHeight),
    );
    var blockHeight = measured.height + 8;
    if (blockHeight < 18) {
      blockHeight = 18;
    }

    if (y + blockHeight > pageHeight - margin) {
      page = document.pages.add();
      y = margin;
    }

    page.graphics.drawString(
      paragraph,
      font,
      bounds: Rect.fromLTWH(margin, y, contentWidth, blockHeight),
      format: format,
      brush: PdfSolidBrush(PdfColor(26, 26, 26)),
    );
    y += blockHeight + 10;
  }

  final result = Uint8List.fromList(await document.save());
  document.dispose();
  return result;
}
