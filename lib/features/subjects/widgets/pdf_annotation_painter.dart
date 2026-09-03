import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Paints PDF annotations for the current page.
///
/// TODO: Advanced text highlight based on real PDF text selection.
class PdfAnnotationPainter extends CustomPainter {
  PdfAnnotationPainter({
    required this.pageData,
    this.currentStroke,
    this.previewHighlight,
  });

  final Map<String, dynamic>? pageData;
  final List<Offset>? currentStroke;
  final Rect? previewHighlight;

  static const _defaultColor = Color(0xFFD6B56D);

  @override
  void paint(Canvas canvas, Size size) {
    if (pageData == null) {
      return;
    }

    _paintHighlights(canvas, pageData!);
    _paintDrawings(canvas, pageData!);
    _paintNotes(canvas, pageData!);

    if (previewHighlight != null) {
      final paint = Paint()
        ..color = _defaultColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawRect(previewHighlight!, paint);
    }

    if (currentStroke != null && currentStroke!.length > 1) {
      _paintStroke(canvas, currentStroke!, _defaultColor, 3);
    }
  }

  void _paintHighlights(Canvas canvas, Map<String, dynamic> page) {
    final highlights = PdfAnnotationDocumentList.listOf(page, 'highlights');

    for (final item in highlights) {
      final rect = Rect.fromLTWH(
        _asDouble(item['x']),
        _asDouble(item['y']),
        _asDouble(item['width']),
        _asDouble(item['height']),
      );
      final paint = Paint()
        ..color = _parseColor(item['color']?.toString()).withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    }
  }

  void _paintDrawings(Canvas canvas, Map<String, dynamic> page) {
    final drawings = PdfAnnotationDocumentList.listOf(page, 'drawings');

    for (final item in drawings) {
      final points = _pointsFromJson(item['points']);
      if (points.length < 2) {
        continue;
      }

      _paintStroke(
        canvas,
        points,
        _parseColor(item['color']?.toString()),
        _asDouble(item['stroke_width'], 3),
      );
    }
  }

  void _paintNotes(Canvas canvas, Map<String, dynamic> page) {
    final notes = PdfAnnotationDocumentList.listOf(page, 'notes');

    for (final item in notes) {
      final center = Offset(_asDouble(item['x']), _asDouble(item['y']));
      final fill = Paint()
        ..color = AppColors.light.primary
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = AppColors.light.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, 10, fill);
      canvas.drawCircle(center, 10, border);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: '!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _paintStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  List<Offset> _pointsFromJson(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((point) => Offset(_asDouble(point['x']), _asDouble(point['y'])))
        .toList();
  }

  Color _parseColor(String? value) {
    if (value == null || value.isEmpty) {
      return _defaultColor;
    }

    final hex = value.replaceAll('#', '');
    if (hex.length == 6) {
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }

    return _defaultColor;
  }

  double _asDouble(dynamic value, [double fallback = 0]) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? fallback;
  }

  @override
  bool shouldRepaint(covariant PdfAnnotationPainter oldDelegate) {
    return oldDelegate.pageData != pageData ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.previewHighlight != previewHighlight;
  }
}

/// Local list helper to avoid circular imports with the model file.
class PdfAnnotationDocumentList {
  static List<Map<String, dynamic>> listOf(
    Map<String, dynamic>? page,
    String key,
  ) {
    final value = page?[key];
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
