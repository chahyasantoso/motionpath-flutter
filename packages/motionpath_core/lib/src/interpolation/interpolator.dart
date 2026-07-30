typedef Easing = double Function(double t);

typedef ValueBlend = Object? Function(Object? from, Object? to, double t);

class MotionPathInterpolators {
  static double linear(double t) => t.clamp(0.0, 1.0);

  static double number(num from, num to, double t) =>
      from + (to - from) * linear(t);

  static Object? value(Object? from, Object? to, double t) {
    if (from is num && to is num) {
      return number(from, to, t);
    }
    if (from is Map<Object?, Object?> && to is Map<Object?, Object?>) {
      final Map<String, Object?> result = <String, Object?>{};
      final Set<Object?> keys = <Object?>{...from.keys, ...to.keys};
      for (final Object? key in keys) {
        if (key is! String) {
          continue;
        }
        final Object? start = from[key];
        final Object? end = to[key];
        result[key] = start == null || end == null
            ? (t < 1 ? start : end)
            : value(start, end, t);
      }
      return result;
    }
    if (from == to) {
      return from;
    }
    return t < 1 ? from : to;
  }
}

class MotionPathStop {
  const MotionPathStop({
    required this.progress,
    required this.value,
    this.ease = MotionPathInterpolators.linear,
  });

  final double progress;
  final Object? value;
  final Easing ease;
}

Object? interpolateStops(
  List<MotionPathStop> stops,
  double progress, {
  ValueBlend blend = MotionPathInterpolators.value,
}) {
  if (stops.isEmpty) return null;
  if (progress <= stops.first.progress) return stops.first.value;
  if (progress >= stops.last.progress) return stops.last.value;
  for (int index = 1; index < stops.length; index++) {
    final MotionPathStop right = stops[index];
    final MotionPathStop left = stops[index - 1];
    if (progress <= right.progress) {
      final double span = right.progress - left.progress;
      final double local = span == 0 ? 1.0 : (progress - left.progress) / span;
      return blend(left.value, right.value, right.ease(local));
    }
  }
  return stops.last.value;
}
