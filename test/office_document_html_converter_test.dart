import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/subjects/data/document_format.dart';
import 'package:rshd/features/subjects/data/office_document_html_converter.dart';
import 'package:rshd/features/subjects/data/office_document_pdf_converter.dart';

void main() {
  test('detects PDF magic bytes', () {
    expect(
      detectDocumentFormat(Uint8List.fromList('%PDF-1.4'.codeUnits)),
      DocumentFormat.pdf,
    );
  });

  test('converts a minimal docx into readable HTML', () {
    final xml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>مرحبا من الملف</w:t></w:r></w:p>
  </w:body>
</w:document>
''';
    final archive = Archive()
      ..addFile(
        ArchiveFile('word/document.xml', xml.length, utf8.encode(xml)),
      );
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final html = const OfficeDocumentHtmlConverter().convert(bytes);

    expect(html, isNotNull);
    expect(html, contains('مرحبا من الملف'));
    expect(html, contains('dir="rtl"'));
  });

  test('converts a minimal docx into annotatable PDF bytes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final xml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>نص للتعليق بالقلم</w:t></w:r></w:p>
  </w:body>
</w:document>
''';
    final archive = Archive()
      ..addFile(
        ArchiveFile('word/document.xml', xml.length, utf8.encode(xml)),
      );
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final pdf = await OfficeDocumentPdfConverter().convert(bytes);

    expect(detectDocumentFormat(pdf), DocumentFormat.pdf);
    expect(utf8.decode(pdf.take(8).toList(), allowMalformed: true), contains('%PDF'));
  });
}
