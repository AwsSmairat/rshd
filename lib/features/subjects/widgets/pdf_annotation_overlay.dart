import 'package:flutter/material.dart';

import '../presentation/pdf_annotation_controller.dart';
import 'pdf_annotation_painter.dart';

/// Overlay layer for drawing PDF annotations on top of the viewer.
///
/// TODO: Add eraser tool.
/// TODO: Add undo/redo.
class PdfAnnotationOverlay extends StatefulWidget {
  const PdfAnnotationOverlay({
    super.key,
    required this.tool,
    required this.pageData,
    required this.onDrawingComplete,
    required this.onNotePositionSelected,
    required this.onHighlightComplete,
    required this.onNoteMarkerTap,
  });

  final PdfAnnotationTool tool;
  final Map<String, dynamic>? pageData;
  final ValueChanged<List<Map<String, dynamic>>> onDrawingComplete;
  final ValueChanged<Offset> onNotePositionSelected;
  final ValueChanged<Rect> onHighlightComplete;
  final ValueChanged<Map<String, dynamic>> onNoteMarkerTap;

  @override
  State<PdfAnnotationOverlay> createState() => _PdfAnnotationOverlayState();
}

class _PdfAnnotationOverlayState extends State<PdfAnnotationOverlay> {
  final List<Offset> _currentStroke = [];
  Offset? _highlightStart;
  Rect? _previewHighlight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: widget.tool == PdfAnnotationTool.view,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            onTapUp: _handleTapUp,
            child: CustomPaint(
              painter: PdfAnnotationPainter(
                pageData: widget.pageData,
                currentStroke:
                    _currentStroke.isEmpty ? null : List.of(_currentStroke),
                previewHighlight: _previewHighlight,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        ..._buildNoteTapTargets(),
      ],
    );
  }

  List<Widget> _buildNoteTapTargets() {
    if (widget.tool != PdfAnnotationTool.view) {
      return const [];
    }

    final notes = PdfAnnotationDocument.listOf(widget.pageData, 'notes');
    return notes.map((note) {
      final x = _asDouble(note['x']);
      final y = _asDouble(note['y']);

      return Positioned(
        left: x - 18,
        top: y - 18,
        child: GestureDetector(
          onTap: () => widget.onNoteMarkerTap(note),
          child: const SizedBox(width: 36, height: 36),
        ),
      );
    }).toList();
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.tool == PdfAnnotationTool.pen) {
      setState(() {
        _currentStroke
          ..clear()
          ..add(details.localPosition);
      });
      return;
    }

    if (widget.tool == PdfAnnotationTool.highlighter) {
      setState(() {
        _highlightStart = details.localPosition;
        _previewHighlight = Rect.fromLTWH(
          details.localPosition.dx,
          details.localPosition.dy,
          0,
          0,
        );
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.tool == PdfAnnotationTool.pen) {
      setState(() {
        _currentStroke.add(details.localPosition);
      });
      return;
    }

    if (widget.tool == PdfAnnotationTool.highlighter && _highlightStart != null) {
      final start = _highlightStart!;
      final current = details.localPosition;
      setState(() {
        _previewHighlight = Rect.fromPoints(start, current);
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.tool == PdfAnnotationTool.pen && _currentStroke.length > 1) {
      final points = _currentStroke
          .map((point) => {'x': point.dx, 'y': point.dy})
          .toList();
      widget.onDrawingComplete(points);
    }

    if (widget.tool == PdfAnnotationTool.highlighter && _previewHighlight != null) {
      final rect = _normalizeRect(_previewHighlight!);
      widget.onHighlightComplete(rect);
    }

    setState(() {
      _currentStroke.clear();
      _highlightStart = null;
      _previewHighlight = null;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.tool == PdfAnnotationTool.note) {
      widget.onNotePositionSelected(details.localPosition);
    }
  }

  Rect _normalizeRect(Rect rect) {
    return Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.left > rect.right ? rect.left : rect.right,
      rect.top > rect.bottom ? rect.top : rect.bottom,
    );
  }

  double _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }
}
