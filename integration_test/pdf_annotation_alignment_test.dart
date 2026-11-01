// On-device check that annotations stay glued to the PDF page.
//
//   flutter test integration_test/pdf_annotation_alignment_test.dart -d <sim>
//
// Each page of a generated PDF carries a solid black box. The real annotation
// layer paints a smaller red rectangle at the same normalised position, inset
// inside the box. While the overlay is aligned with the page, the red patch is
// framed by black on all four sides; any drift — the bug this guards against,
// typically after a pinch zoom — breaks the frame on at least one side.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' show PdfViewerController;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:rshd/features/pdf_editor/controllers/pdf_editor_controller.dart';
import 'package:rshd/features/pdf_editor/models/annotation_enums.dart';
import 'package:rshd/features/pdf_editor/models/pdf_editor_models.dart';
import 'package:rshd/features/pdf_editor/services/pdf_coordinate_mapper.dart';
import 'package:rshd/features/pdf_editor/widgets/pdf_document_view.dart';
import 'package:rshd/features/pdf_editor/widgets/pdf_page_annotation_layer.dart';

/// Black box per page, normalised to the page (x, y, w, h).
const _boxes = {
  1: Rect.fromLTWH(0.30, 0.25, 0.40, 0.20),
  2: Rect.fromLTWH(0.10, 0.60, 0.40, 0.20),
};

/// Red overlay sits inside the box, leaving this much black around it.
const _insetX = 0.05;
const _insetY = 0.04;

Future<Uint8List> _buildPdf() async {
  final document = sf.PdfDocument();
  document.pageSettings.margins.all = 0;
  document.pageSettings.size = sf.PdfPageSize.a4;
  for (final box in _boxes.values) {
    final page = document.pages.add();
    final size = page.getClientSize();
    page.graphics.drawRectangle(
      brush: sf.PdfSolidBrush(sf.PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(
        box.left * size.width,
        box.top * size.height,
        box.width * size.width,
        box.height * size.height,
      ),
    );
  }
  final bytes = Uint8List.fromList(await document.save());
  document.dispose();
  return bytes;
}

PdfEditorAnnotation _redPatch(int page) {
  final box = _boxes[page]!;
  return PdfEditorAnnotation(
    id: 'patch-$page',
    type: AnnotationType.shape,
    pageNumber: page,
    x: box.left + _insetX,
    y: box.top + _insetY,
    width: box.width - _insetX * 2,
    height: box.height - _insetY * 2,
    data: const {
      'shape': 'rectangle',
      'stroke_color': '#FF0000',
      'fill_color': '#FF0000',
      'stroke_width': 0.001,
      'opacity': 1,
    },
  );
}

Widget _layerFor(Size size, int page) {
  void noop([Object? a, Object? b, Object? c, Object? d]) {}
  return PdfPageAnnotationLayer(
    tool: PdfEditorTool.view,
    annotations: [_redPatch(page)],
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
    onInkComplete: (a, b) => noop(),
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

final _boundaryKey = GlobalKey();

Future<ui.Image> _capture() async {
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return boundary.toImage(pixelRatio: 1);
}

/// Waits for pdfium to rasterise the visible pages.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

class _Frame {
  _Frame(this.redBounds, this.sides);
  final Rect redBounds;
  final Map<String, bool> sides;
  bool get framed => sides.values.every((black) => black);
}

/// Finds the red patch and checks the black frame around it.
Future<_Frame> _inspect(ui.Image image) async {
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final w = image.width, h = image.height;
  int r(int x, int y) => data.getUint8((y * w + x) * 4);
  int g(int x, int y) => data.getUint8((y * w + x) * 4 + 1);
  int b(int x, int y) => data.getUint8((y * w + x) * 4 + 2);
  // The patch is a thin bright-red outline around a translucent red fill
  // that reads dark over the black box, so "red" means red-dominant.
  bool isRed(int x, int y) => r(x, y) > g(x, y) + 40 && r(x, y) > b(x, y) + 40;
  bool isBlack(int x, int y) => r(x, y) < 60 && g(x, y) < 60 && b(x, y) < 60;

  var minX = w, minY = h, maxX = -1, maxY = -1;
  // Every pixel: the outline is one pixel wide and a stride would skip it.
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (isRed(x, y)) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < 0) return _Frame(Rect.zero, {'red-visible': false});

  final red = Rect.fromLTRB(minX * 1.0, minY * 1.0, maxX * 1.0, maxY * 1.0);
  // Frame thickness relative to the red patch, from the normalised insets.
  final box = _boxes[1]!;
  final ringX = red.width * _insetX / (box.width - _insetX * 2);
  final ringY = red.height * _insetY / (box.height - _insetY * 2);
  final cx = red.center.dx.round(), cy = red.center.dy.round();

  bool blackAt(double x, double y) {
    final xi = x.round(), yi = y.round();
    if (xi < 0 || yi < 0 || xi >= w || yi >= h) return true; // off-screen
    return isBlack(xi, yi);
  }

  return _Frame(red, {
    'left': blackAt(red.left - ringX / 2, cy * 1.0),
    'right': blackAt(red.right + ringX / 2, cy * 1.0),
    'top': blackAt(cx * 1.0, red.top - ringY / 2),
    'bottom': blackAt(cx * 1.0, red.bottom + ringY / 2),
  });
}

Future<void> _save(ui.Image image, String name) async {
  // `--dart-define=ALIGNMENT_SHOTS=<dir>` keeps the shots after the test app
  // is uninstalled (the simulator can write to host paths).
  const shots = String.fromEnvironment('ALIGNMENT_SHOTS');
  final dir = shots.isNotEmpty
      ? Directory(shots)
      : await getApplicationDocumentsDirectory();
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${dir.path}/$name.png')
    ..writeAsBytesSync(png!.buffer.asUint8List());
  debugPrint('ALIGNMENT-SHOT ${file.path}');
}

Future<PdfViewerController> _pump(
  WidgetTester tester,
  Uint8List bytes,
  PdfReadingDirection direction,
) async {
  final controller = PdfViewerController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: RepaintBoundary(
          key: _boundaryKey,
          child: PdfDocumentView(
            key: ValueKey(direction),
            bytes: bytes,
            sourceName: 'alignment-${direction.name}',
            controller: controller,
            direction: direction,
            interactive: true,
            pageOverlayBuilder: _layerFor,
            onReady: (_, _) {},
            onPageChanged: (_) {},
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  return controller;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final direction in PdfReadingDirection.values) {
    testWidgets(
      'annotation stays on the page when zooming (${direction.name})',
      (tester) async {
        final bytes = await _buildPdf();
        final controller = await _pump(tester, bytes, direction);

        final atRest = await _capture();
        final rest = await _inspect(atRest);
        await _save(atRest, '${direction.name}_zoom1');
        expect(rest.framed, isTrue, reason: 'at zoom 1: ${rest.sides}');

        // Zoom hard onto the box on page 1 — the case that used to drift.
        final page = controller.layout.pageLayouts.first;
        final box = _boxes[1]!;
        final target = Offset(
          page.left + page.width * box.center.dx,
          page.top + page.height * box.center.dy,
        );
        // The zoom animation only advances on pumped frames, so start it and
        // pump rather than awaiting it (which would wait forever).
        unawaited(
          controller.setZoom(
            target,
            controller.currentZoom * 2.5,
            duration: Duration.zero,
          ),
        );
        await _settle(tester);

        final zoomed = await _capture();
        final z = await _inspect(zoomed);
        await _save(zoomed, '${direction.name}_zoom25');
        expect(z.framed, isTrue, reason: 'at zoom 2.5: ${z.sides}');
        expect(
          z.redBounds.width,
          greaterThan(rest.redBounds.width * 2),
          reason: 'the annotation must grow with the page',
        );
      },
    );
  }
}
