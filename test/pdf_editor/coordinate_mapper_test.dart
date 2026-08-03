import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/models/pdf_editor_models.dart';
import 'package:rshd/features/pdf_editor/services/pdf_coordinate_mapper.dart';

void main() {
  group('PdfPageLayoutMetrics', () {
    test('converts screen and normalized coordinates consistently', () {
      final metrics = PdfPageLayoutMetrics(
        pdfPageSize: Size(595, 842),
        viewportSize: Size(400, 800),
        zoomLevel: 1,
      );

      const normalized = NormalizedPoint(0.5, 0.5);
      final screen = metrics.normalizedToScreen(normalized);
      final back = metrics.screenToNormalized(screen);

      expect(back.nx, closeTo(0.5, 0.001));
      expect(back.ny, closeTo(0.5, 0.001));
    });

    test('zoom scales display size without breaking normalized mapping', () {
      final base = PdfPageLayoutMetrics(
        pdfPageSize: const Size(595, 842),
        viewportSize: const Size(400, 800),
        zoomLevel: 1,
      );
      final zoomed = PdfPageLayoutMetrics(
        pdfPageSize: const Size(595, 842),
        viewportSize: const Size(400, 800),
        zoomLevel: 2,
      );

      const point = NormalizedPoint(0.25, 0.75);
      final baseScreen = base.normalizedToScreen(point);
      final zoomedScreen = zoomed.normalizedToScreen(point);

      expect(zoomedScreen.dx - zoomed.pageTopLeft.dx,
          closeTo(2 * (baseScreen.dx - base.pageTopLeft.dx), 0.5));
      expect(zoomed.screenToNormalized(zoomedScreen).nx, closeTo(0.25, 0.001));
    });
  });

  group('PdfAnnotationDocumentV2 migration', () {
    test('migrates legacy pixel coordinates to v2 schema', () {
      final migrated = PdfAnnotationDocumentV2.migrateFromLegacy({
        'pages': {
          '1': {
            'drawings': [
              {
                'id': '1',
                'points': [
                  {'x': 100, 'y': 200},
                  {'x': 150, 'y': 250},
                ],
              },
            ],
          },
        },
      });

      expect(migrated['version'], 2);
      final page = migrated['pages']['1'] as Map<String, dynamic>;
      final annotations = page['annotations'] as List<dynamic>;
      expect(annotations, isNotEmpty);
    });
  });
}
