// On-device check of writing mode gestures:
//
//   flutter test integration_test/pdf_pen_pinch_test.dart -d <sim>
//
// With the pen active, one finger must draw without moving the page, and a
// two-finger pinch must zoom without leaving a stroke behind.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart' show PdfViewerController;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:rshd/features/pdf_editor/controllers/pdf_editor_controller.dart';
import 'package:rshd/features/pdf_editor/models/annotation_enums.dart';
import 'package:rshd/features/pdf_editor/services/pdf_coordinate_mapper.dart';
import 'package:rshd/features/pdf_editor/widgets/pdf_document_view.dart';
import 'package:rshd/features/pdf_editor/widgets/pdf_page_annotation_layer.dart';

Future<Uint8List> _buildPdf() async {
  final document = sf.PdfDocument();
  document.pageSettings.size = sf.PdfPageSize.a4;
  document.pages.add();
  document.pages.add();
  final bytes = Uint8List.fromList(await document.save());
  document.dispose();
  return bytes;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final direction in PdfReadingDirection.values) {
    testWidgets('pen draws with one finger, pinch zooms (${direction.name})', (
      tester,
    ) async {
      final strokes = <int>[];
      final controller = PdfViewerController();

      Widget layer(Size size, int page) {
        void noop([Object? a, Object? b, Object? c, Object? d]) {}
        return PdfPageAnnotationLayer(
          tool: PdfEditorTool.pen,
          annotations: const [],
          metrics: PdfPageLayoutMetrics(
            displayPageSize: size,
            viewportSize: size,
            zoomLevel: 1,
          ),
          penSettings: const PenSettings(),
          highlighterSettings: const HighlighterSettings(),
          eraserMode: EraserMode.partial,
          eraserSize: 0.02,
          allowFingerDrawing: true,
          shapeTool: PdfEditorShapeTool.rectangle,
          selectedAnnotationId: null,
          pageNumber: page,
          onInkComplete: (points, _) => strokes.add(page),
          onHighlightComplete: (a, b, c, d) => noop(),
          onShapeComplete: (a, b, c, d) => noop(),
          onNoteTap: (a, b) => noop(),
          onTextTap: (a, b) => noop(),
          onErase: (a) => noop(),
          onNoteMarkerTap: (a) => noop(),
          onSelectAnnotation: (a) => noop(),
          onMoveAnnotation: (a, b, c) => noop(),
          onBatchBegin: () {},
          onBatchEnd: () {},
          onAnnotationTap: (a) => noop(),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfDocumentView(
              bytes: await _buildPdf(),
              sourceName: 'pen-${direction.name}',
              controller: controller,
              direction: direction,
              interactive: false,
              pageOverlayBuilder: layer,
              onReady: (_, _) {},
              onPageChanged: (_) {},
            ),
          ),
        ),
      );
      await _settle(tester);

      final page = controller.layout.pageLayouts.first;
      final center = controller.documentToGlobal(page.center)!;
      final zoomBefore = controller.currentZoom;
      final offsetBefore = controller.value.getTranslation();

      // One finger: a stroke, and the page stays put.
      final pen = await tester.startGesture(center);
      for (var i = 1; i <= 10; i++) {
        await pen.moveTo(center + Offset(i * 8, i * 5));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await pen.up();
      await _settle(tester);
      expect(strokes, [1], reason: 'one finger draws one stroke');
      expect(controller.currentZoom, zoomBefore);
      expect(
        controller.value.getTranslation(),
        offsetBefore,
        reason: 'drawing must not scroll the page',
      );

      // Two fingers: pinch out, no stroke.
      final a = await tester.startGesture(center - const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      final b = await tester.startGesture(center + const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      for (var i = 1; i <= 12; i++) {
        await a.moveTo(center - Offset(30.0 + i * 8, 0));
        await b.moveTo(center + Offset(30.0 + i * 8, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      await b.up();
      await _settle(tester);
      expect(strokes, [1], reason: 'a pinch must not leave a stroke');
      expect(
        controller.currentZoom,
        greaterThan(zoomBefore * 1.5),
        reason: 'two fingers zoom while the pen is active',
      );
    });
  }
}
