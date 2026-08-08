import 'dart:math' as math;
import 'dart:ui';

import '../models/annotation_enums.dart';
import '../models/pdf_editor_models.dart';

class AnnotationHitTest {
  const AnnotationHitTest._();

  static PdfEditorAnnotation? findAt(
    List<PdfEditorAnnotation> annotations,
    NormalizedPoint point, {
    double tolerance = 0.025,
  }) {
    for (final annotation in annotations.reversed) {
      if (hits(annotation, point, tolerance: tolerance)) {
        return annotation;
      }
    }
    return null;
  }

  static bool hits(
    PdfEditorAnnotation annotation,
    NormalizedPoint point, {
    double tolerance = 0.025,
  }) {
    switch (annotation.type) {
      case AnnotationType.note:
      case AnnotationType.text:
        final dx = annotation.x - point.nx;
        final dy = annotation.y - point.ny;
        if (annotation.type == AnnotationType.text &&
            annotation.width > 0 &&
            annotation.height > 0) {
          final rect = Rect.fromLTWH(
            annotation.x,
            annotation.y,
            annotation.width,
            annotation.height,
          );
          return rect.inflate(tolerance).contains(Offset(point.nx, point.ny));
        }
        return math.sqrt(dx * dx + dy * dy) <= tolerance * 2;
      case AnnotationType.highlighter:
        if ((annotation.width.abs() > 0.001 || annotation.height.abs() > 0.001) &&
            annotation.data['points'] == null) {
          final left =
              annotation.width >= 0 ? annotation.x : annotation.x + annotation.width;
          final top = annotation.height >= 0
              ? annotation.y
              : annotation.y + annotation.height;
          final rect = Rect.fromLTWH(
            left,
            top,
            annotation.width.abs(),
            annotation.height.abs(),
          );
          return rect.inflate(tolerance).contains(Offset(point.nx, point.ny));
        }
        return _hitsStroke(annotation, point, tolerance);
      case AnnotationType.ink:
        return _hitsStroke(annotation, point, tolerance);
      case AnnotationType.shape:
        if (annotation.width.abs() > 0.001 || annotation.height.abs() > 0.001) {
          final left =
              annotation.width >= 0 ? annotation.x : annotation.x + annotation.width;
          final top = annotation.height >= 0
              ? annotation.y
              : annotation.y + annotation.height;
          final rect = Rect.fromLTWH(
            left,
            top,
            annotation.width.abs(),
            annotation.height.abs(),
          );
          return rect.inflate(tolerance).contains(Offset(point.nx, point.ny));
        }
        return false;
      case AnnotationType.image:
        return false;
    }
  }

  static bool _hitsStroke(
    PdfEditorAnnotation annotation,
    NormalizedPoint point,
    double tolerance,
  ) {
    final rawPoints = annotation.data['points'];
    if (rawPoints is! List) return false;

    final radiusSquared = tolerance * tolerance;
    for (final raw in rawPoints.whereType<Map>()) {
      final p = NormalizedPoint.fromJson(Map<String, dynamic>.from(raw));
      final dx = p.nx - point.nx;
      final dy = p.ny - point.ny;
      if ((dx * dx + dy * dy) <= radiusSquared) {
        return true;
      }
    }
    return false;
  }
}
