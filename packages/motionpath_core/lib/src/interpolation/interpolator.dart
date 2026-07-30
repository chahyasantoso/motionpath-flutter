import 'easing.dart';

/// Value interpolation primitives shared by every track.
class MotionPathInterpolators {
  /// No easing, retained as a stable public entry point.
  static double linear(double t) => MotionPathEasing.linear(t);

  /// Interpolates two numbers at the already eased [t].
  static double number(num from, num to, double t) {
    final double start = from.toDouble();
    return start + (to.toDouble() - start) * t;
  }

  /// Interpolates any two authored values.
  ///
  /// Numbers blend, identical values pass through, and everything else snaps at
  /// the end of the segment. The core never invents a value it cannot
  /// meaningfully blend.
  static Object? value(Object? from, Object? to, double t) {
    if (from is num && to is num) {
      return number(from, to, t);
    }
    if (from == to) {
      return from;
    }
    return t < 1 ? from : to;
  }
}

/// One authored keyframe stop.
class MotionPathStop {
  /// Creates a stop.
  const MotionPathStop({
    required this.progress,
    required this.value,
    this.ease = MotionPathEasing.linear,
  });

  /// Normalized position in `[0, 1]`.
  final double progress;

  /// Authored value at [progress].
  final Object? value;

  /// Easing applied on the segment ending at this stop.
  final Easing ease;
}

/// Samples a monotonic list of [stops] at [progress].
Object? interpolateStops(List<MotionPathStop> stops, double progress) {
  if (stops.isEmpty) {
    return null;
  }
  if (progress <= stops.first.progress) {
    return stops.first.value;
  }
  if (progress >= stops.last.progress) {
    return stops.last.value;
  }
  for (int index = 1; index < stops.length; index++) {
    final MotionPathStop right = stops[index];
    final MotionPathStop left = stops[index - 1];
    if (progress <= right.progress) {
      final double span = right.progress - left.progress;
      final double local = span == 0 ? 1.0 : (progress - left.progress) / span;
      return MotionPathInterpolators.value(
        left.value,
        right.value,
        right.ease(local),
      );
    }
  }
  return stops.last.value;
}
