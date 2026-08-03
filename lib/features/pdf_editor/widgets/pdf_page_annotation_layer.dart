import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../controllers/pdf_editor_controller.dart';
import '../models/annotation_enums.dart';
import '../models/pdf_editor_models.dart';
import '../services/pdf_coordinate_mapper.dart';
import '../utils/path_smoother.dart';
import 'painters/pdf_annotation_painters.dart';

class PdfPageAnnotationLayer extends StatefulWidget {
  const PdfPageAnnotationLayer({
    super.key,
    required this.tool,
    required this.annotations,
    required this.metrics,
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
  });

  final PdfEditorTool tool;
  final List<PdfEditorAnnotation> annotations;
  final PdfPageLayoutMetrics metrics;
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

  @override
  State<PdfPageAnnotationLayer> createState() => _PdfPageAnnotationLayerState();
}

class _PdfPageAnnotationLayerState extends State<PdfPageAnnotationLayer> {
  final List<Offset> _currentStroke = [];
  Offset? _dragStart;
  Rect? _previewRect;
  String? _movingAnnotationId;
  Offset? _moveStartNormalized;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fromRect(
          rect: widget.metrics.pageRect,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: ShapeAnnotationPainter(
                annotations: widget.annotations,
                metrics: widget.metrics,
                previewRect: _previewRect,
                previewShape: widget.shapeTool,
                previewColor: widget.penSettings.color,
              ),
              foregroundPainter: InkAnnotationPainter(
                annotations: widget.annotations,
                metrics: widget.metrics,
                currentStroke:
                    _currentStroke.isEmpty ? null : List.of(_currentStroke),
                currentColor: _activeColor,
                currentStrokeWidth: _activeStrokeWidth,
                currentOpacity: _activeOpacity,
                selectedId: widget.selectedAnnotationId,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: widget.metrics.pageRect,
          child: _buildInteractionLayer(),
        ),
        ..._buildNoteMarkers(),
        ..._buildTextBoxes(),
      ],
    );
  }

  Widget _buildInteractionLayer() {
    if (widget.tool == PdfEditorTool.view) {
      return const SizedBox.expand();
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: widget.tool == PdfEditorTool.note
            ? (details) => _handleNoteTap(details.localPosition)
            : widget.tool == PdfEditorTool.text
                ? (details) => _handleTextTap(details.localPosition)
                : null,
        child: const SizedBox.expand(),
      ),
    );
  }

  Color get _activeColor => switch (widget.tool) {
        PdfEditorTool.highlighter => widget.highlighterSettings.color,
        _ => widget.penSettings.color,
      };

  double get _activeStrokeWidth => switch (widget.tool) {
        PdfEditorTool.highlighter => widget.metrics.normalizedStrokeWidth(
            widget.highlighterSettings.strokeWidth,
          ),
        PdfEditorTool.pen => widget.metrics.normalizedStrokeWidth(
            widget.penSettings.strokeWidth,
          ),
        _ => 3,
      };

  double get _activeOpacity => switch (widget.tool) {
        PdfEditorTool.highlighter => widget.highlighterSettings.opacity,
        _ => widget.penSettings.opacity,
      };

  bool _allowPointer(PointerEvent event) {
    if (widget.tool == PdfEditorTool.view) return false;
    if (event.kind == PointerDeviceKind.stylus) return true;
    if (event.kind == PointerDeviceKind.invertedStylus) return true;
    if (widget.allowFingerDrawing) return true;
    return widget.tool == PdfEditorTool.note ||
        widget.tool == PdfEditorTool.text ||
        widget.tool == PdfEditorTool.lasso;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_allowPointer(event)) return;
    if (!widget.metrics.containsScreenPoint(event.localPosition)) return;

    final normalized = widget.metrics.screenToNormalized(event.localPosition);

    if (widget.tool == PdfEditorTool.eraser) {
      widget.onErase(normalized);
      return;
    }

    if (widget.tool == PdfEditorTool.lasso) {
      final selected = _findAnnotationAt(normalized);
      widget.onSelectAnnotation(selected?.id);
      if (selected != null) {
        _movingAnnotationId = selected.id;
        _moveStartNormalized = Offset(normalized.nx, normalized.ny);
      }
      return;
    }

    if (widget.tool == PdfEditorTool.pen ||
        widget.tool == PdfEditorTool.highlighter) {
      setState(() {
        _currentStroke
          ..clear()
          ..add(event.localPosition);
      });
      return;
    }

    if (widget.tool == PdfEditorTool.shapes ||
        widget.tool == PdfEditorTool.highlighter) {
      setState(() {
        _dragStart = event.localPosition;
        _previewRect = Rect.fromLTWH(
          event.localPosition.dx,
          event.localPosition.dy,
          0,
          0,
        );
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_allowPointer(event)) return;

    if (_movingAnnotationId != null && _moveStartNormalized != null) {
      final normalized = widget.metrics.screenToNormalized(event.localPosition);
      final deltaX = normalized.nx - _moveStartNormalized!.dx;
      final deltaY = normalized.ny - _moveStartNormalized!.dy;
      final annotation = widget.annotations
          .firstWhere((item) => item.id == _movingAnnotationId);
      widget.onMoveAnnotation(
        _movingAnnotationId!,
        (annotation.x + deltaX).clamp(0.0, 1.0),
        (annotation.y + deltaY).clamp(0.0, 1.0),
      );
      _moveStartNormalized = Offset(normalized.nx, normalized.ny);
      return;
    }

    if (widget.tool == PdfEditorTool.eraser) {
      widget.onErase(widget.metrics.screenToNormalized(event.localPosition));
      return;
    }

    if ((widget.tool == PdfEditorTool.pen ||
            widget.tool == PdfEditorTool.highlighter) &&
        _currentStroke.isNotEmpty) {
      setState(() {
        _currentStroke.add(event.localPosition);
      });
      return;
    }

    if (_dragStart != null &&
        (widget.tool == PdfEditorTool.shapes ||
            widget.tool == PdfEditorTool.highlighter)) {
      setState(() {
        _previewRect = Rect.fromPoints(_dragStart!, event.localPosition);
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_movingAnnotationId != null) {
      _movingAnnotationId = null;
      _moveStartNormalized = null;
      return;
    }

    if ((widget.tool == PdfEditorTool.pen ||
            widget.tool == PdfEditorTool.highlighter) &&
        _currentStroke.length > 1) {
      final simplified = PathSmoother.simplify(_currentStroke);
      final normalized = PdfCoordinateMapper.screenPointsToNormalized(
        simplified,
        widget.metrics,
      );
      widget.onInkComplete(
        normalized,
        widget.tool == PdfEditorTool.highlighter
            ? AnnotationType.highlighter
            : AnnotationType.ink,
      );
    }

    if (_previewRect != null && _dragStart != null) {
      final rect = _normalizedRect(_previewRect!);
      if (widget.tool == PdfEditorTool.shapes) {
        widget.onShapeComplete(rect.left, rect.top, rect.width, rect.height);
      } else if (widget.tool == PdfEditorTool.highlighter) {
        widget.onHighlightComplete(rect.left, rect.top, rect.width, rect.height);
      }
    }

    setState(() {
      _currentStroke.clear();
      _dragStart = null;
      _previewRect = null;
    });
  }

  Rect _normalizedRect(Rect screenRect) {
    final topLeft =
        widget.metrics.screenToNormalized(screenRect.topLeft);
    final bottomRight =
        widget.metrics.screenToNormalized(screenRect.bottomRight);
    return Rect.fromLTRB(
      topLeft.nx < bottomRight.nx ? topLeft.nx : bottomRight.nx,
      topLeft.ny < bottomRight.ny ? topLeft.ny : bottomRight.ny,
      topLeft.nx > bottomRight.nx ? topLeft.nx : bottomRight.nx,
      topLeft.ny > bottomRight.ny ? topLeft.ny : bottomRight.ny,
    );
  }

  void _handleNoteTap(Offset localPosition) {
    if (!widget.metrics.containsScreenPoint(localPosition)) return;
    final point = widget.metrics.screenToNormalized(localPosition);
    widget.onNoteTap(point.nx, point.ny);
  }

  void _handleTextTap(Offset localPosition) {
    if (!widget.metrics.containsScreenPoint(localPosition)) return;
    final point = widget.metrics.screenToNormalized(localPosition);
    widget.onTextTap(point.nx, point.ny);
  }

  PdfEditorAnnotation? _findAnnotationAt(NormalizedPoint point) {
    for (final annotation in widget.annotations.reversed) {
      if (annotation.type == AnnotationType.note ||
          annotation.type == AnnotationType.text) {
        final distance = (Offset(point.nx, point.ny) -
                Offset(annotation.x, annotation.y))
            .distance;
        if (distance < 0.05) return annotation;
      }
    }
    return null;
  }

  List<Widget> _buildNoteMarkers() {
    return widget.annotations
        .where((item) => item.type == AnnotationType.note)
        .map((note) {
      final screen = widget.metrics.normalizedToScreen(
        NormalizedPoint(note.x, note.y),
      );
      return Positioned(
        left: screen.dx - 14,
        top: screen.dy - 14,
        child: GestureDetector(
          onTap: () => widget.onNoteMarkerTap(note),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1F3A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD6B56D), width: 2),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.sticky_note_2, color: Colors.white, size: 14),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTextBoxes() {
    return widget.annotations
        .where((item) => item.type == AnnotationType.text)
        .map((textBox) {
      final rect = widget.metrics.normalizedRectToScreen(
        x: textBox.x,
        y: textBox.y,
        width: textBox.width,
        height: textBox.height,
      );
      return Positioned.fromRect(
        rect: rect,
        child: IgnorePointer(
          child: Text(
            textBox.data['text']?.toString() ?? '',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _parseColor(textBox.data['color']?.toString()),
              fontSize: widget.metrics.displaySize.width *
                  (textBox.data['font_size'] as num? ?? 0.025).toDouble(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _parseColor(String? value) {
    if (value == null) return const Color(0xFF0B1F3A);
    final hex = value.replaceAll('#', '');
    if (hex.length == 6) {
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return const Color(0xFF0B1F3A);
  }
}
