import 'dart:ui';

/// Reduces ink stroke points while preserving shape.
class PathSmoother {
  const PathSmoother._();

  static List<Offset> simplify(List<Offset> points, {double tolerance = 2.0}) {
    if (points.length <= 2) return List.of(points);

    final result = <Offset>[points.first];
    for (var i = 1; i < points.length - 1; i++) {
      final previous = result.last;
      final current = points[i];
      if ((current - previous).distance >= tolerance) {
        result.add(current);
      }
    }
    result.add(points.last);
    return result;
  }
}
