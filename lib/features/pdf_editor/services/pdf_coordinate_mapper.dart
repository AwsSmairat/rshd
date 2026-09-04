import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../models/pdf_editor_models.dart';

/// Maps between screen coordinates and normalized PDF page coordinates (0–1).
class PdfPageLayoutMetrics {
  PdfPageLayoutMetrics({
    required this.displayPageSize,
    required this.viewportSize,
    required this.zoomLevel,
    this.scrollOffset = Offset.zero,
  });

  /// Builds metrics that mirror Syncfusion [SfPdfViewer] page sizing on mobile.
  factory PdfPageLayoutMetrics.fromViewport({
    required Size pdfPageSize,
    required Size viewportSize,
    required double zoomLevel,
    Offset scrollOffset = Offset.zero,
    bool fitToWidth = true,
  }) {
    final fitted = fitToWidth
        ? BoxConstraints.tightFor(
            width: viewportSize.width,
          ).constrainSizeAndAttemptToPreserveAspectRatio(pdfPageSize)
        : BoxConstraints.tightFor(
            height: viewportSize.height,
          ).constrainSizeAndAttemptToPreserveAspectRatio(pdfPageSize);
    return PdfPageLayoutMetrics(
      displayPageSize: fitted,
      viewportSize: viewportSize,
      zoomLevel: zoomLevel,
      scrollOffset: scrollOffset,
    );
  }

  /// Display size of the page at zoom 1 (after Syncfusion fit).
  final Size displayPageSize;
  final Size viewportSize;
  final double zoomLevel;
  final Offset scrollOffset;

  Size get displaySize => Size(
    displayPageSize.width * zoomLevel,
    displayPageSize.height * zoomLevel,
  );

  /// Top-left of the visible page in viewport coordinates.
  Offset get pageTopLeft {
    final center = Offset(
      (viewportSize.width - displaySize.width) / 2,
      (viewportSize.height - displaySize.height) / 2,
    );
    // At zoom 1 the page is centered; scrollOffset is unreliable here.
    if (zoomLevel <= 1.0) {
      return center;
    }
    return center -
        Offset(scrollOffset.dx * zoomLevel, scrollOffset.dy * zoomLevel);
  }

  Rect get pageRect => pageTopLeft & displaySize;

  /// Page bounds relative to the page itself, for painters whose canvas
  /// origin already sits at [pageTopLeft].
  Rect get pageLocalRect => Offset.zero & displaySize;

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
    return pageTopLeft + normalizedToPageLocal(point);
  }

  Offset normalizedToPageLocal(NormalizedPoint point) {
    return Offset(point.nx * displaySize.width, point.ny * displaySize.height);
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

  Rect normalizedRectToPageLocal({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final topLeft = normalizedToPageLocal(NormalizedPoint(x, y));
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

  static List<Offset> normalizedPointsToPageLocal(
    List<NormalizedPoint> points,
    PdfPageLayoutMetrics metrics,
  ) {
    return points.map(metrics.normalizedToPageLocal).toList();
  }

  static List<NormalizedPoint> screenPointsToNormalized(
    List<Offset> points,
    PdfPageLayoutMetrics metrics,
  ) {
    return points.map(metrics.screenToNormalized).toList();
  }

  /// Largest box with the page's aspect ratio that fits inside [viewportSize].
  ///
  /// Hosting [SfPdfViewer] in a box of exactly this size makes the rendered
  /// page fill it edge to edge, so the annotation overlay can be aligned to the
  /// box instead of guessing where the viewer placed the page.
  static Size fitPageInViewport({
    required Size pageSize,
    required Size viewportSize,
  }) {
    if (pageSize.width <= 0 ||
        pageSize.height <= 0 ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0) {
      return Size.zero;
    }
    final scale = math.min(
      viewportSize.width / pageSize.width,
      viewportSize.height / pageSize.height,
    );
    return Size(pageSize.width * scale, pageSize.height * scale);
  }

  /// Returns the page size as displayed by Syncfusion (accounts for 90°/270° rotation).
  static Size effectivePageSize({
    required double width,
    required double height,
    required int rotationDegrees,
  }) {
    if (rotationDegrees == 90 || rotationDegrees == 270) {
      return Size(height, width);
    }
    return Size(width, height);
  }
}
