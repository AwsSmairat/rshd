import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../controllers/pdf_editor_controller.dart';
import '../models/annotation_enums.dart';
import '../models/pdf_editor_models.dart';
import '../services/pdf_coordinate_mapper.dart';
import '../utils/annotation_hit_test.dart';
import '../utils/path_smoother.dart';
import 'painters/pdf_annotation_painters.dart';
import '../../../core/l10n/app_strings.dart';

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
    required this.onBatchBegin,
    required this.onBatchEnd,
    required this.onAnnotationTap,
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
  final VoidCallback onBatchBegin;
  final VoidCallback onBatchEnd;
  /// Fired once, on pointer up, when a lasso tap lands on an annotation.
  final void Function(PdfEditorAnnotation annotation) onAnnotationTap;

  @override
  State<PdfPageAnnotationLayer> createState() => _PdfPageAnnotationLayerState();
}

class _PdfPageAnnotationLayerState extends State<PdfPageAnnotationLayer> {
  final List<Offset> _currentStroke = [];
  Offset? _dragStart;
  Rect? _previewRect;
  String? _movingAnnotationId;
  Offset? _moveStartNormalized;
  bool _batchActive = false;
  int _activePointers = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
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
                  selectedId: widget.selectedAnnotationId,
                ),
                foregroundPainter: InkAnnotationPainter(
                  annotations: widget.annotations,
                  metrics: widget.metrics,
                  currentStroke: _currentStroke.isEmpty
                      ? null
                      : List.of(_currentStroke),
                  currentColor: _activeColor,
                  currentStrokeWidth: _activeStrokeWidth,
                  currentOpacity: _activeOpacity,
                  selectedId: widget.selectedAnnotationId,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          if (widget.tool != PdfEditorTool.view)
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: _handleTapUp,
                child: const SizedBox.expand(),
              ),
            ),
          ..._buildNoteMarkers(),
          ..._buildTextBoxes(),
        ],
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

  /// Converts viewport coordinates to normalized page coordinates.
  NormalizedPoint _viewportToNormalized(Offset viewportPoint) {
    return widget.metrics.screenToNormalized(viewportPoint);
  }

  Offset _viewportToPageLocal(Offset viewportPoint) {
    return viewportPoint - widget.metrics.pageTopLeft;
  }

  bool _isInsidePageViewport(Offset viewportPoint) {
    return widget.metrics.containsScreenPoint(viewportPoint);
  }

  /// Pointer events inside [pageRect] use page-local coordinates (0..displaySize).
  NormalizedPoint _localToNormalized(Offset pageLocal) {
    final size = widget.metrics.displaySize;
    if (size.width <= 0 || size.height <= 0) {
      return const NormalizedPoint(0, 0);
    }
    return NormalizedPoint(
      (pageLocal.dx / size.width).clamp(0.0, 1.0),
      (pageLocal.dy / size.height).clamp(0.0, 1.0),
    );
  }

  void _ensureBatchStarted() {
    if (!_batchActive) {
      widget.onBatchBegin();
      _batchActive = true;
    }
  }

  void _finishBatchIfNeeded() {
    if (!_batchActive) return;
    widget.onBatchEnd();
    _batchActive = false;
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers > 1) return;
    if (!_allowPointer(event)) return;
    if (!_isInsidePageViewport(event.localPosition)) return;

    final pageLocal = _viewportToPageLocal(event.localPosition);
    final normalized = _viewportToNormalized(event.localPosition);

    if (widget.tool == PdfEditorTool.eraser) {
      _ensureBatchStarted();
      widget.onErase(normalized);
      return;
    }

    if (widget.tool == PdfEditorTool.lasso) {
      final selected = AnnotationHitTest.findAt(widget.annotations, normalized);
      widget.onSelectAnnotation(selected?.id);
      if (selected != null) {
        _ensureBatchStarted();
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
          ..add(pageLocal);
      });
      return;
    }

    if (widget.tool == PdfEditorTool.shapes) {
      setState(() {
        _dragStart = pageLocal;
        _previewRect = Rect.fromLTWH(pageLocal.dx, pageLocal.dy, 0, 0);
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointers > 1) return;
    if (!_allowPointer(event)) return;

    final pageLocal = _viewportToPageLocal(event.localPosition);

    if (_movingAnnotationId != null && _moveStartNormalized != null) {
      final normalized = _viewportToNormalized(event.localPosition);
      final deltaX = normalized.nx - _moveStartNormalized!.dx;
      final deltaY = normalized.ny - _moveStartNormalized!.dy;
      // Undo or the eraser can drop the annotation mid-drag.
      final index = widget.annotations.indexWhere(
        (item) => item.id == _movingAnnotationId,
      );
      if (index < 0) {
        _movingAnnotationId = null;
        _moveStartNormalized = null;
        _finishBatchIfNeeded();
        return;
      }
      final annotation = widget.annotations[index];
      widget.onMoveAnnotation(
        _movingAnnotationId!,
        (annotation.x + deltaX).clamp(0.0, 1.0),
        (annotation.y + deltaY).clamp(0.0, 1.0),
      );
      _moveStartNormalized = Offset(normalized.nx, normalized.ny);
      return;
    }

    if (widget.tool == PdfEditorTool.eraser) {
      widget.onErase(_viewportToNormalized(event.localPosition));
      return;
    }

    if ((widget.tool == PdfEditorTool.pen ||
            widget.tool == PdfEditorTool.highlighter) &&
        _currentStroke.isNotEmpty) {
      setState(() {
        _currentStroke.add(pageLocal);
      });
      return;
    }

    if (_dragStart != null && widget.tool == PdfEditorTool.shapes) {
      setState(() {
        _previewRect = Rect.fromPoints(_dragStart!, pageLocal);
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = _activePointers > 0 ? _activePointers - 1 : 0;
    if (_activePointers > 0) return;
    _completePointerAction();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = _activePointers > 0 ? _activePointers - 1 : 0;
    if (_activePointers > 0) return;
    _completePointerAction(cancelled: true);
  }

  void _completePointerAction({bool cancelled = false}) {
    if (_movingAnnotationId != null) {
      _movingAnnotationId = null;
      _moveStartNormalized = null;
      _finishBatchIfNeeded();
      return;
    }

    if (widget.tool == PdfEditorTool.eraser) {
      _finishBatchIfNeeded();
      return;
    }

    if (!cancelled &&
        (widget.tool == PdfEditorTool.pen ||
            widget.tool == PdfEditorTool.highlighter) &&
        _currentStroke.length > 1) {
      final simplified = PathSmoother.simplify(_currentStroke);
      final normalized = simplified.map(_localToNormalized).toList();
      widget.onInkComplete(
        normalized,
        widget.tool == PdfEditorTool.highlighter
            ? AnnotationType.highlighter
            : AnnotationType.ink,
      );
    }

    if (!cancelled && _previewRect != null && _dragStart != null) {
      final rect = _normalizedRect(_previewRect!);
      if (widget.tool == PdfEditorTool.shapes) {
        widget.onShapeComplete(rect.left, rect.top, rect.width, rect.height);
      }
    }

    setState(() {
      _currentStroke.clear();
      _dragStart = null;
      _previewRect = null;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isInsidePageViewport(details.localPosition)) return;
    final point = _viewportToNormalized(details.localPosition);
    final pageLocal = _viewportToPageLocal(details.localPosition);

    if (widget.tool == PdfEditorTool.note) {
      _handleNoteTap(pageLocal);
      return;
    }

    if (widget.tool == PdfEditorTool.text) {
      _handleTextTap(pageLocal);
      return;
    }

    if (widget.tool == PdfEditorTool.lasso) {
      final selected = AnnotationHitTest.findAt(widget.annotations, point);
      widget.onSelectAnnotation(selected?.id);
      // Note markers own their own tap handler, so skip them here.
      if (selected != null && selected.type != AnnotationType.note) {
        widget.onAnnotationTap(selected);
      }
    }
  }

  Rect _normalizedRect(Rect pageLocalRect) {
    final topLeft = _localToNormalized(pageLocalRect.topLeft);
    final bottomRight = _localToNormalized(pageLocalRect.bottomRight);
    return Rect.fromLTRB(
      topLeft.nx < bottomRight.nx ? topLeft.nx : bottomRight.nx,
      topLeft.ny < bottomRight.ny ? topLeft.ny : bottomRight.ny,
      topLeft.nx > bottomRight.nx ? topLeft.nx : bottomRight.nx,
      topLeft.ny > bottomRight.ny ? topLeft.ny : bottomRight.ny,
    );
  }

  void _handleNoteTap(Offset pageLocal) {
    final point = _localToNormalized(pageLocal);
    widget.onNoteTap(point.nx, point.ny);
  }

  void _handleTextTap(Offset pageLocal) {
    final point = _localToNormalized(pageLocal);
    widget.onTextTap(point.nx, point.ny);
  }

  List<Widget> _buildNoteMarkers() {
    return widget.annotations
        .where((item) => item.type == AnnotationType.note)
        .map((note) {
          final screen = widget.metrics.normalizedToScreen(
            NormalizedPoint(note.x, note.y),
          );
          final selected = widget.selectedAnnotationId == note.id;
          return Positioned(
            left: screen.dx - 14,
            top: screen.dy - 14,
            child: GestureDetector(
              onTap: () {
                if (widget.tool == PdfEditorTool.lasso) {
                  widget.onSelectAnnotation(note.id);
                }
                widget.onNoteMarkerTap(note);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1F3A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFD6B56D)
                        : const Color(0xFFD6B56D),
                    width: selected ? 3 : 2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.sticky_note_2,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          );
        })
        .toList();
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
          final selected = widget.selectedAnnotationId == textBox.id;
          final directionName = textBox.data['text_direction']?.toString();
          final textDirection = directionName == 'ltr'
              ? TextDirection.ltr
              : TextDirection.rtl;

          return Positioned.fromRect(
            rect: rect,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: selected
                    ? BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFD6B56D),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : const BoxDecoration(),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text(AppStrings.of(context).t(textBox.data['text']?.toString() ?? ''),
                    textAlign: TextAlign.right,
                    textDirection: textDirection,
                    style: TextStyle(
                      color: _parseColor(textBox.data['color']?.toString()),
                      fontSize:
                          widget.metrics.displaySize.width *
                          (textBox.data['font_size'] as num? ?? 0.025)
                              .toDouble(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        })
        .toList();
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
