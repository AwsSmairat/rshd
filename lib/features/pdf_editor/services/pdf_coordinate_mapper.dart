import 'dart:math';
import 'dart:ui';

import '../models/pdf_editor_models.dart';

/// Maps between screen coordinates and normalized PDF page coordinates (0–1).
class PdfPageLayoutMetrics {
  PdfPageLayoutMetrics({
    required this.pdfPageSize,
    required this.viewportSize,
    required this.zoomLevel,
    this.scrollOffset = Offset.zero,
  });

  final Size pdfPageSize;
  final Size viewportSize;
  final double zoomLevel;
  final Offset scrollOffset;

  double get _fitScale {
    if (pdfPageSize.width <= 0 || pdfPageSize.height <= 0) {
      return 1;
    }
    return min(
      viewportSize.width / pdfPageSize.width,
      viewportSize.height / pdfPageSize.height,
    );
  }

  Size get displaySize => Size(
        pdfPageSize.width * _fitScale * zoomLevel,
        pdfPageSize.height * _fitScale * zoomLevel,
      );

  Offset get pageTopLeft => Offset(
        (viewportSize.width - displaySize.width) / 2,
        (viewportSize.height - displaySize.height) / 2,
      ) -
      scrollOffset;

  Rect get pageRect => pageTopLeft & displaySize;

  bool containsScreenPoint(Offset screenPoint) {
    return pageRect.contains(screenPoint);
  }

  NormalizedPoint screenToNormalized(Offset screenPoint) {
    final local = screenPoint - pageTopLeft;
    return NormalizedPoint(
      (local.dx / displaySize.width).clamp(0.0, 1.0),
      (local.dy / displaySize.height).clamp(0.0, 1.0),
    );
  }

  Offset normalizedToScreen(NormalizedPoint point) {
    return pageTopLeft +
        Offset(
          point.nx * displaySize.width,
          point.ny * displaySize.height,
        );
  }

  Rect normalizedRectToScreen({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final topLeft = normalizedToScreen(NormalizedPoint(x, y));
    return Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      width * displaySize.width,
      height * displaySize.height,
    );
  }

  double normalizedStrokeWidth(double normalizedWidth) {
    return normalizedWidth * displaySize.width;
  }

  double screenStrokeToNormalized(double screenWidth) {
    if (displaySize.width <= 0) return screenWidth;
    return screenWidth / displaySize.width;
  }
}

class PdfCoordinateMapper {
  const PdfCoordinateMapper._();

  static List<Offset> normalizedPointsToScreen(
    List<NormalizedPoint> points,
    PdfPageLayoutMetrics metrics,
  ) {
    return points.map(metrics.normalizedToScreen).toList();
  }

  static List<NormalizedPoint> screenPointsToNormalized(
    List<Offset> points,
    PdfPageLayoutMetrics metrics,
  ) {
    return points.map(metrics.screenToNormalized).toList();
  }
}
