import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class OfficeDocumentHtmlConverter {
  const OfficeDocumentHtmlConverter();

  List<String> extractParagraphs(Uint8List bytes) {
    try {
      return _docxParagraphs(bytes);
    } catch (_) {
      return _pptxParagraphs(bytes);
    }
  }

  String? convert(Uint8List bytes) {
    final paragraphs = extractParagraphs(bytes);
    if (paragraphs.isEmpty) {
      return null;
    }
    return _wrap(paragraphs.map((text) => '<p>${_escape(text)}</p>').join('\n'));
  }

  List<String> _docxParagraphs(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final document = archive.findFile('word/document.xml');
    if (document == null) {
      throw const FormatException('ملف Word غير صالح');
    }

    final xml = utf8.decode(document.content, allowMalformed: true);
    final paragraphs = <String>[];
    for (final paragraph in xml.split(RegExp(r'</w:p>'))) {
      final text = _xmlTexts(paragraph, const ['w:t']).join().trim();
      if (text.isNotEmpty) {
        paragraphs.add(text);
      }
    }

    if (paragraphs.isEmpty) {
      throw const FormatException('لا يمكن قراءة محتوى ملف Word');
    }
    return paragraphs;
  }

  List<String> _pptxParagraphs(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final slides = archive.files
        .where(
          (file) =>
              file.name.startsWith('ppt/slides/slide') &&
              file.name.endsWith('.xml'),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (slides.isEmpty) {
      throw const FormatException('ملف العرض غير صالح');
    }

    final paragraphs = <String>[];
    for (var index = 0; index < slides.length; index++) {
      final xml = utf8.decode(slides[index].content, allowMalformed: true);
      final texts = _xmlTexts(xml, const ['a:t'])
          .map((text) => text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      paragraphs.add('شريحة ${index + 1}');
      if (texts.isEmpty) {
        paragraphs.add('—');
      } else {
        paragraphs.addAll(texts);
      }
    }
    return paragraphs;
  }

  List<String> _xmlTexts(String xml, List<String> tags) {
    final pattern = RegExp(
      '<(?:${tags.map(RegExp.escape).join('|')})[^>]*>([^<]*)</(?:${tags.map(RegExp.escape).join('|')})>',
    );
    return pattern
        .allMatches(xml)
        .map((match) => _decodeEntities(match.group(1) ?? ''))
        .toList();
  }

  String _wrap(String body) {
    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body { margin: 0; padding: 20px; background: #F6F1E7; color: #1A1A1A; font-family: sans-serif; line-height: 1.85; }
  p { margin: 0 0 12px; }
  h2 { font-size: 16px; margin: 24px 0 8px; color: #0B1F3A; }
</style>
</head>
<body>$body</body>
</html>
''';
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  String _decodeEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}
