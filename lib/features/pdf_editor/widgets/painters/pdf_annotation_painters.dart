import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/annotation_enums.dart';
import '../../models/pdf_editor_models.dart';
import '../../services/pdf_coordinate_mapper.dart';

class InkAnnotationPainter extends CustomPainter {
  InkAnnotationPainter({
    required this.annotations,
    required this.metrics,
    this.currentStroke,
    this.currentColor = AppColors.primary,
    this.currentStrokeWidth = 3,
    this.currentOpacity = 1,
    this.selectedId,
  });

  final List<PdfEditorAnnotation> annotations;
  final PdfPageLayoutMetrics metrics;
  final List<Offset>? currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;
  final double currentOpacity;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(metrics.pageRect);

    for (final annotation in annotations) {
      if (annotation.type == AnnotationType.ink ||
          annotation.type == AnnotationType.highlighter) {
        _paintInk(canvas, annotation);
      }
    }

    if (currentStroke != null && currentStroke!.length > 1) {
      _paintScreenStroke(
        canvas,
        currentStroke!,
        currentColor.withValues(alpha: currentOpacity),
        currentStrokeWidth,
        false,
      );
    }

    canvas.restore();
  }

  void _paintInk(Canvas canvas, PdfEditorAnnotation annotation) {
    final rawPoints = annotation.data['points'];
    if (rawPoints is! List) return;

    final points = rawPoints
        .whereType<Map>()
        .map(
          (entry) => NormalizedPoint.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
    if (points.length < 2) return;

    final screenPoints = PdfCoordinateMapper.normalizedPointsToScreen(
      points,
      metrics,
    );
    final color = _parseColor(annotation.data['color']?.toString());
    final opacity = _asDouble(annotation.data['opacity'], 1);
    final strokeWidth = metrics.normalizedStrokeWidth(
      _asDouble(annotation.data['stroke_width'], 0.004),
    );

    _paintScreenStroke(
      canvas,
      screenPoints,
      color.withValues(alpha: opacity),
      strokeWidth,
      annotation.type == AnnotationType.highlighter,
    );

    if (selectedId == annotation.id) {
      final bounds = _boundsForPoints(screenPoints);
      final border = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(bounds.inflate(4), border);
    }
  }

  void _paintScreenStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double strokeWidth,
    bool isHighlighter,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (isHighlighter) {
      paint.blendMode = BlendMode.multiply;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  Rect _boundsForPoints(List<Offset> points) {
    var left = points.first.dx;
    var top = points.first.dy;
    var right = points.first.dx;
    var bottom = points.first.dy;
    for (final point in points.skip(1)) {
      left = left < point.dx ? left : point.dx;
      top = top < point.dy ? top : point.dy;
      right = right > point.dx ? right : point.dx;
      bottom = bottom > point.dy ? bottom : point.dy;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Color _parseColor(String? value) {
    if (value == null || value.isEmpty) return AppColors.accent;
    final hex = value.replaceAll('#', '');
    if (hex.length == 6) {
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    if (hex.length == 8) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return AppColors.accent;
  }

  double _asDouble(dynamic value, [double fallback = 0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  @override
  bool shouldRepaint(covariant InkAnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.metrics.pageRect != metrics.pageRect ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.selectedId != selectedId;
  }
}

class ShapeAnnotationPainter extends CustomPainter {
  ShapeAnnotationPainter({
    required this.annotations,
    required this.metrics,
    this.previewRect,
    this.previewShape = PdfEditorShapeTool.rectangle,
    this.previewColor = AppColors.primary,
    this.previewStrokeWidth = 2,
    this.selectedId,
  });

  final List<PdfEditorAnnotation> annotations;
  final PdfPageLayoutMetrics metrics;
  final Rect? previewRect;
  final PdfEditorShapeTool previewShape;
  final Color previewColor;
  final double previewStrokeWidth;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(metrics.pageRect);

    for (final annotation in annotations) {
      if (annotation.type == AnnotationType.highlighter &&
          annotation.width > 0 &&
          annotation.height > 0) {
        _paintHighlightRect(canvas, annotation);
      } else if (annotation.type == AnnotationType.shape) {
        _paintShape(canvas, annotation);
      }
    }

    if (previewRect != null) {
      _paintPreview(canvas, previewRect!);
    }

    canvas.restore();
  }

  void _paintHighlightRect(Canvas canvas, PdfEditorAnnotation annotation) {
    final rect = metrics.normalizedRectToScreen(
      x: annotation.x,
      y: annotation.y,
      width: annotation.width,
      height: annotation.height,
    );
    final paint = Paint()
      ..color = _parseColor(
        annotation.data['color']?.toString(),
      ).withValues(alpha: _asDouble(annotation.data['opacity'], 0.35))
      ..blendMode = BlendMode.multiply
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
  }

  void _paintShape(Canvas canvas, PdfEditorAnnotation annotation) {
    final rect = metrics.normalizedRectToScreen(
      x: annotation.x,
      y: annotation.y,
      width: annotation.width,
      height: annotation.height,
    );
    final strokeColor = _parseColor(
      annotation.data['stroke_color']?.toString(),
    );
    final fillColor = annotation.data['fill_color'] != null
        ? _parseColor(annotation.data['fill_color']?.toString())
        : null;
    final strokeWidth = metrics.normalizedStrokeWidth(
      _asDouble(annotation.data['stroke_width'], 0.003),
    );
    final shapeName = annotation.data['shape']?.toString() ?? 'rectangle';

    final stroke = Paint()
      ..color = strokeColor.withValues(
        alpha: _asDouble(annotation.data['opacity'], 1),
      )
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final fill = fillColor == null
        ? null
        : (Paint()
            ..color = fillColor.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill);

    switch (shapeName) {
      case 'line':
      case 'arrow':
        canvas.drawLine(rect.topLeft, rect.bottomRight, stroke);
        if (shapeName == 'arrow') {
          _drawArrowHead(canvas, rect.topLeft, rect.bottomRight, stroke);
        }
      case 'circle':
        canvas.drawOval(rect, stroke);
        if (fill != null) canvas.drawOval(rect, fill);
      default:
        canvas.drawRect(rect, stroke);
        if (fill != null) canvas.drawRect(rect, fill);
    }

    if (selectedId == annotation.id) {
      final border = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(rect.inflate(4), border);
    }
  }

  void _paintPreview(Canvas canvas, Rect rect) {
    final stroke = Paint()
      ..color = previewColor
      ..strokeWidth = previewStrokeWidth
      ..style = PaintingStyle.stroke;

    switch (previewShape) {
      case PdfEditorShapeTool.line:
      case PdfEditorShapeTool.arrow:
        canvas.drawLine(rect.topLeft, rect.bottomRight, stroke);
      case PdfEditorShapeTool.circle:
        canvas.drawOval(rect, stroke);
      default:
        canvas.drawRect(rect, stroke);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    const headLength = 12.0;
    final angle = (end - start).direction;
    final p1 = end + Offset.fromDirection(angle + 2.6, headLength);
    final p2 = end + Offset.fromDirection(angle - 2.6, headLength);
    canvas.drawLine(end, p1, paint);
    canvas.drawLine(end, p2, paint);
  }

  Color _parseColor(String? value) {
    if (value == null || value.isEmpty) return AppColors.primary;
    final hex = value.replaceAll('#', '');
    if (hex.length == 6) {
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return AppColors.primary;
  }

  double _asDouble(dynamic value, [double fallback = 0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  @override
  bool shouldRepaint(covariant ShapeAnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.previewRect != previewRect ||
        oldDelegate.metrics.pageRect != metrics.pageRect ||
        oldDelegate.selectedId != selectedId;
  }
}
