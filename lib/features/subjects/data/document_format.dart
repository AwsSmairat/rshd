import 'dart:typed_data';

enum DocumentFormat { pdf, docx, pptx, oleDoc, unknown }

DocumentFormat detectDocumentFormat(Uint8List bytes) {
  if (bytes.length >= 5 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46) {
    return DocumentFormat.pdf;
  }

  if (bytes.length >= 8 &&
      bytes[0] == 0xD0 &&
      bytes[1] == 0xCF &&
      bytes[2] == 0x11 &&
      bytes[3] == 0xE0) {
    return DocumentFormat.oleDoc;
  }

  if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
    final latin1 = String.fromCharCodes(
      bytes.take(bytes.length < 200 ? bytes.length : 200),
    );
    if (latin1.contains('word/')) {
      return DocumentFormat.docx;
    }
    if (latin1.contains('ppt/')) {
      return DocumentFormat.pptx;
    }
    return DocumentFormat.docx;
  }

  return DocumentFormat.unknown;
}
