import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Loads the bundled Arabic-capable font for PDF text export.
class PdfArabicFontLoader {
  PdfArabicFontLoader({this.assetPath = 'assets/fonts/NotoNaskhArabic-Regular.ttf'});

  static final arabicPattern =
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');

  final String assetPath;
  Uint8List? _fontBytes;

  Future<Uint8List> loadFontBytes() async {
    _fontBytes ??= (await rootBundle.load(assetPath)).buffer.asUint8List();
    return _fontBytes!;
  }

  Future<PdfTrueTypeFont> createFont(double size) async {
    final bytes = await loadFontBytes();
    return PdfTrueTypeFont(bytes, size, style: PdfFontStyle.regular);
  }

  PdfTrueTypeFont createFontFromBytes(Uint8List bytes, double size) {
    return PdfTrueTypeFont(bytes, size, style: PdfFontStyle.regular);
  }

  static bool containsArabic(String text) => arabicPattern.hasMatch(text);

  static PdfStringFormat textFormat(String text) {
    final hasArabic = containsArabic(text);
    return PdfStringFormat(
      textDirection:
          hasArabic ? PdfTextDirection.rightToLeft : PdfTextDirection.leftToRight,
      alignment: hasArabic ? PdfTextAlignment.right : PdfTextAlignment.left,
      wordWrap: PdfWordWrapType.word,
    );
  }
}
