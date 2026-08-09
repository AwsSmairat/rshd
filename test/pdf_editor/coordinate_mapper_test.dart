import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/models/pdf_editor_models.dart';
import 'package:rshd/features/pdf_editor/services/pdf_coordinate_mapper.dart';

void main() {
  group('PdfPageLayoutMetrics', () {
    test('converts screen and normalized coordinates consistently', () {
      final metrics = PdfPageLayoutMetrics.fromViewport(
        pdfPageSize: const Size(595, 842),
        viewportSize: const Size(400, 800),
        zoomLevel: 1,
      );

      const normalized = NormalizedPoint(0.5, 0.5);
      final screen = metrics.normalizedToScreen(normalized);
      final back = metrics.screenToNormalized(screen);

      expect(back.nx, closeTo(0.5, 0.001));
      expect(back.ny, closeTo(0.5, 0.001));
    });

    test('scroll offset shifts page rect only when zoomed', () {
      final base = PdfPageLayoutMetrics.fromViewport(
        pdfPageSize: const Size(595, 842),
        viewportSize: const Size(400, 800),
        zoomLevel: 2,
      );
      final scrolled = PdfPageLayoutMetrics.fromViewport(
        pdfPageSize: const Size(595, 842),
        viewportSize: const Size(400, 800),
        zoomLevel: 2,
        scrollOffset: const Offset(10, 20),
      );

      expect(scrolled.pageTopLeft.dx, closeTo(base.pageTopLeft.dx - 20, 0.001));
      expect(scrolled.pageTopLeft.dy, closeTo(base.pageTopLeft.dy - 40, 0.001));
    });

    test('ignores scroll offset at zoom 1', () {
      final base = PdfPageLayoutMetrics.fromViewport(
        pdfPageSize: const Size(595, 842),
        viewportSize: const Size(400, 800),
        zoomLevel: 1,
      );
      final scrolled = PdfPageLayoutMetrics.fromViewport(
        pdfPageSize: const Size(595, 842),
        viewportSize: const Size(400, 800),
        zoomLevel: 1,
        scrollOffset: const Offset(50, 80),
      );

      expect(scrolled.pageTopLeft, base.pageTopLeft);
    });

    test('zoom scales display size without breaking normalized mapping', () {
      final base = PdfPageLayoutMetrics.fromViewport(
        pdfPageSize: const Size(595, 842),
        viewportSize: const Size(400, 800),
        zoomLevel: 1,
      );
      final zoomed = PdfPageLayoutMetrics.fromViewport(
        pdfPageSize: const Size(595, 842),
        viewportSize: const Size(400, 800),
        zoomLevel: 2,
      );

      const point = NormalizedPoint(0.25, 0.75);
      final baseScreen = base.normalizedToScreen(point);
      final zoomedScreen = zoomed.normalizedToScreen(point);

      expect(
        zoomedScreen.dx - zoomed.pageTopLeft.dx,
        closeTo(2 * (baseScreen.dx - base.pageTopLeft.dx), 0.5),
      );
      expect(zoomed.screenToNormalized(zoomedScreen).nx, closeTo(0.25, 0.001));
    });

    test('effective page size swaps dimensions for 90 degree rotation', () {
      final size = PdfCoordinateMapper.effectivePageSize(
        width: 595,
        height: 842,
        rotationDegrees: 90,
      );
      expect(size.width, 842);
      expect(size.height, 595);
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
