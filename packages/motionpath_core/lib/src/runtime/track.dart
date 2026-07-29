import '../interpolation/interpolator.dart';

class MotionPathTrackRuntime {
  MotionPathTrackRuntime(this.id, {this.stops = const <MotionPathStop>[]});
  final String id;
  final List<MotionPathStop> stops;
  double progress = 0;
  final List<void Function(Map<String, Object?>)> _listeners = <void Function(Map<String, Object?>)>[];

  Map<String, Object?> compose() => <String, Object?>{'value': interpolateStops(stops, progress), 'progress': progress};

  void seek(double value) {
    progress = value.clamp(0.0, 1.0);
    final patch = compose();
    for (final listener in List<void Function(Map<String, Object?>)>.from(_listeners)) {
      listener(patch);
    }
  }

  void subscribe(void Function(Map<String, Object?>) listener) => _listeners.add(listener);
  void dispose() => _listeners.clear();
}
