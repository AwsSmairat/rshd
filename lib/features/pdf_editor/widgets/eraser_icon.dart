import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An outlined eraser, drawn to sit beside the outlined Material tool icons:
/// a tilted block with its rubber tip set apart, resting on a line.
/// Material Icons has no eraser glyph of its own.
class EraserIcon extends StatelessWidget {
  const EraserIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final side = size ?? iconTheme.size ?? 24;
    return SizedBox.square(
      dimension: side,
      child: CustomPaint(
        painter: _EraserPainter(color ?? iconTheme.color ?? Colors.black),
      ),
    );
  }
}

class _EraserPainter extends CustomPainter {
  _EraserPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 24-unit grid, like the icon font.
    final unit = size.width / 24;
    canvas.scale(unit);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The surface it rubs on.
    canvas.drawLine(const Offset(9.5, 21.2), const Offset(20.5, 21.2), stroke);

    canvas.save();
    canvas.translate(12.5, 10);
    canvas.rotate(-math.pi / 4);

    const body = Rect.fromLTRB(-8.5, -4.25, 8.5, 4.25);
    const radius = Radius.circular(2);

    // The rubber tip, lightly filled so it reads as a different material.
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(body, radius));
    canvas.drawRect(
      const Rect.fromLTRB(-8.5, -4.25, -2.5, 4.25),
      Paint()..color = color.withValues(alpha: 0.28),
    );
    canvas.restore();

    canvas.drawRRect(RRect.fromRectAndRadius(body, radius), stroke);
    canvas.drawLine(
      const Offset(-2.5, -4.25),
      const Offset(-2.5, 4.25),
      stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EraserPainter oldDelegate) => oldDelegate.color != color;
}
