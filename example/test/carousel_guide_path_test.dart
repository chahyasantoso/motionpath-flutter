import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/carousel_scene.dart';

Offset _authoredPoint(int index) {
  final Map<String, Object?> point =
      carouselPathPoints[index]! as Map<String, Object?>;
  return Offset(
    (point['x']! as num).toDouble(),
    (point['y']! as num).toDouble(),
  );
}

void main() {
  test('the guide is one contour that spans the authored endpoints', () {
    final List<PathMetric> metrics =
        carouselGuidePath().computeMetrics().toList();
    expect(metrics, hasLength(1));

    final PathMetric contour = metrics.single;
    expect(contour.length, greaterThan(0));

    final Offset start = contour.getTangentForOffset(0)!.position;
    final Offset end = contour.getTangentForOffset(contour.length)!.position;
    final Offset authoredStart = _authoredPoint(0);
    final Offset authoredEnd = _authoredPoint(carouselPathPoints.length - 1);

    expect(start.dx, closeTo(authoredStart.dx, 1e-6));
    expect(start.dy, closeTo(authoredStart.dy, 1e-6));
    expect(end.dx, closeTo(authoredEnd.dx, 1e-6));
    expect(end.dy, closeTo(authoredEnd.dy, 1e-6));
  });

  test('the guide encloses every authored point', () {
    final Rect bounds = carouselGuidePath().getBounds().inflate(1e-3);
    for (int index = 0; index < carouselPathPoints.length; index++) {
      expect(
        bounds.contains(_authoredPoint(index)),
        isTrue,
        reason: 'authored point $index escaped the painted guide bounds',
      );
    }
  });
}
