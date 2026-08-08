import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/services/pdf_export_filename.dart';

void main() {
  group('PdfExportFilename', () {
    test('builds course and document filename with date', () {
      final name = PdfExportFilename.build(
        courseTitle: 'الرياضيات',
        documentTitle: 'الدرس الأول',
        exportedAt: DateTime(2026, 8, 8),
      );

      expect(name, 'الرياضيات_الدرس_الأول_annotated_2026-08-08.pdf');
    });

    test('sanitizes unsafe filesystem characters', () {
      final name = PdfExportFilename.build(
        courseTitle: 'Math/101',
        documentTitle: 'Unit:2*Notes?',
        exportedAt: DateTime(2026, 1, 15),
      );

      expect(name, 'Math_101_Unit_2_Notes_annotated_2026-01-15.pdf');
    });

    test('falls back to document-only filename', () {
      final name = PdfExportFilename.build(
        documentTitle: 'Worksheet',
        exportedAt: DateTime(2026, 3, 1),
      );

      expect(name, 'Worksheet_annotated_2026-03-01.pdf');
    });

    test('sanitizeSegment removes slashes and spaces', () {
      expect(
        PdfExportFilename.sanitizeSegment('  hello world / test  '),
        'hello_world_test',
      );
    });
  });
}
