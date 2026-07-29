typedef Easing = double Function(double t);

class MotionPathInterpolators {
  static double linear(double t) => t.clamp(0.0, 1.0);

  static double number(num from, num to, double t) => from + (to - from) * linear(t);

  static Object? value(Object? from, Object? to, double t) {
    if (from is num && to is num) return number(from, to, t);
    if (from == to) return from;
    return t < 1 ? from : to;
  }
}

class MotionPathStop {
  const MotionPathStop({required this.progress, required this.value, this.ease = MotionPathInterpolators.linear});
  final double progress;
  final Object? value;
  final Easing ease;
}

Object? interpolateStops(List<MotionPathStop> stops, double progress) {
  if (stops.isEmpty) return null;
  if (progress <= stops.first.progress) return stops.first.value;
  if (progress >= stops.last.progress) return stops.last.value;
  for (var index = 1; index < stops.length; index++) {
    final right = stops[index];
    final left = stops[index - 1];
    if (progress <= right.progress) {
      final span = right.progress - left.progress;
      final local = span == 0 ? 1.0 : (progress - left.progress) / span;
      return MotionPathInterpolators.value(left.value, right.value, right.ease(local));
    }
  }
  return stops.last.value;
}
