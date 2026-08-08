import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../controllers/pdf_editor_controller.dart';
import '../models/annotation_enums.dart';
import '../models/pdf_editor_models.dart';
import '../services/pdf_coordinate_mapper.dart';
import 'pdf_page_annotation_layer.dart';

/// Keeps the annotation overlay aligned with [PdfViewerController] pan/zoom
/// without rebuilding [SfPdfViewer] on every scroll frame.
class PdfAnnotationOverlayHost extends StatefulWidget {
  const PdfAnnotationOverlayHost({
    super.key,
    required this.pdfController,
    required this.viewportSize,
    required this.pdfPageSize,
    required this.pageRotationDegrees,
    required this.passThroughTouches,
    required this.tool,
    required this.annotations,
    required this.penSettings,
    required this.highlighterSettings,
    required this.eraserMode,
    required this.eraserSize,
    required this.allowFingerDrawing,
    required this.shapeTool,
    required this.selectedAnnotationId,
    required this.pageNumber,
    required this.onInkComplete,
    required this.onHighlightComplete,
    required this.onShapeComplete,
    required this.onNoteTap,
    required this.onTextTap,
    required this.onErase,
    required this.onNoteMarkerTap,
    required this.onSelectAnnotation,
    required this.onMoveAnnotation,
    required this.onBatchBegin,
    required this.onBatchEnd,
    required this.onTextAnnotationTap,
  });

  final PdfViewerController pdfController;
  final Size viewportSize;
  final Size pdfPageSize;
  final int pageRotationDegrees;
  final bool passThroughTouches;
  final PdfEditorTool tool;
  final List<PdfEditorAnnotation> annotations;
  final PenSettings penSettings;
  final HighlighterSettings highlighterSettings;
  final EraserMode eraserMode;
  final double eraserSize;
  final bool allowFingerDrawing;
  final PdfEditorShapeTool shapeTool;
  final String? selectedAnnotationId;
  final int pageNumber;
  final void Function(List<NormalizedPoint> points, AnnotationType type)
      onInkComplete;
  final void Function(double x, double y, double width, double height)
      onHighlightComplete;
  final void Function(double x, double y, double width, double height)
      onShapeComplete;
  final void Function(double x, double y) onNoteTap;
  final void Function(double x, double y) onTextTap;
  final void Function(NormalizedPoint point) onErase;
  final void Function(PdfEditorAnnotation note) onNoteMarkerTap;
  final void Function(String? id) onSelectAnnotation;
  final void Function(String id, double x, double y) onMoveAnnotation;
  final VoidCallback onBatchBegin;
  final VoidCallback onBatchEnd;
  final void Function(PdfEditorAnnotation annotation) onTextAnnotationTap;

  @override
  State<PdfAnnotationOverlayHost> createState() =>
      _PdfAnnotationOverlayHostState();
}

class _PdfAnnotationOverlayHostState extends State<PdfAnnotationOverlayHost> {
  final _transform = _ViewerTransformNotifier();

  @override
  void initState() {
    super.initState();
    widget.pdfController.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTransformSync();
    });
  }

  @override
  void didUpdateWidget(covariant PdfAnnotationOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfController != widget.pdfController) {
      oldWidget.pdfController.removeListener(_onControllerChanged);
      widget.pdfController.addListener(_onControllerChanged);
    }
    _onControllerChanged();
  }

  @override
  void dispose() {
    widget.pdfController.removeListener(_onControllerChanged);
    _transform.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _transform.update(
      scroll: widget.pdfController.scrollOffset,
      zoom: widget.pdfController.zoomLevel,
    );
  }

  void _startTransformSync() {
    if (!mounted) return;
    _transform.update(
      scroll: widget.pdfController.scrollOffset,
      zoom: widget.pdfController.zoomLevel,
    );
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      if (mounted) _startTransformSync();
    });
  }

  PdfPageLayoutMetrics _buildMetrics() {
    final effectiveSize = PdfCoordinateMapper.effectivePageSize(
      width: widget.pdfPageSize.width,
      height: widget.pdfPageSize.height,
      rotationDegrees: widget.pageRotationDegrees,
    );
    return PdfPageLayoutMetrics.fromViewport(
      pdfPageSize: effectiveSize,
      viewportSize: widget.viewportSize,
      zoomLevel: _transform.zoom,
      scrollOffset: _transform.scroll,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _transform,
      builder: (context, _) {
        return IgnorePointer(
          ignoring: widget.passThroughTouches,
          child: PdfPageAnnotationLayer(
            tool: widget.tool,
            annotations: widget.annotations,
            metrics: _buildMetrics(),
            penSettings: widget.penSettings,
            highlighterSettings: widget.highlighterSettings,
            eraserMode: widget.eraserMode,
            eraserSize: widget.eraserSize,
            allowFingerDrawing: widget.allowFingerDrawing,
            shapeTool: widget.shapeTool,
            selectedAnnotationId: widget.selectedAnnotationId,
            pageNumber: widget.pageNumber,
            onInkComplete: widget.onInkComplete,
            onHighlightComplete: widget.onHighlightComplete,
            onShapeComplete: widget.onShapeComplete,
            onNoteTap: widget.onNoteTap,
            onTextTap: widget.onTextTap,
            onErase: widget.onErase,
            onNoteMarkerTap: widget.onNoteMarkerTap,
            onSelectAnnotation: widget.onSelectAnnotation,
            onMoveAnnotation: widget.onMoveAnnotation,
            onBatchBegin: widget.onBatchBegin,
            onBatchEnd: widget.onBatchEnd,
            onTextAnnotationTap: widget.onTextAnnotationTap,
          ),
        );
      },
    );
  }
}

class _ViewerTransformNotifier extends ChangeNotifier {
  Offset scroll = Offset.zero;
  double zoom = 1;

  void update({required Offset scroll, required double zoom}) {
    if (this.scroll == scroll && this.zoom == zoom) return;
    this.scroll = scroll;
    this.zoom = zoom;
    notifyListeners();
  }
}
