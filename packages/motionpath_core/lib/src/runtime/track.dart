import '../contract/motionpath_types.dart';
import '../interpolation/interpolator.dart';

class MotionPathTrackRuntime {
  MotionPathTrackRuntime(this.id, {this.stops = const <MotionPathStop>[]});
  final String id;
  final List<MotionPathStop> stops;
  double progress = 0;
  final List<void Function(Map<String, Object?>)> _listeners = <void Function(Map<String, Object?>)>[];

  Map<String, Object?> compose() => <String, Object?>{'value': interpolateStops(stops, progress), 'progress': progress};

  void seek(double value) {
    progress = value.clamp(0.0, 1.0).toDouble();
    final patch = compose();
    for (final listener in List<void Function(Map<String, Object?>)>.from(_listeners)) listener(patch);
  }

  void subscribe(void Function(Map<String, Object?>) listener) => _listeners.add(listener);
  void dispose() => _listeners.clear();
}

List<MotionPathStop> stopsFromKeyframe(Object? raw) {
  if (raw is! Map) return const <MotionPathStop>[];
  final stops = raw['stops'];
  if (stops is! List) return const <MotionPathStop>[];
  final result = <MotionPathStop>[];
  for (final candidate in stops) {
    if (candidate is! Map) continue;
    final progress = candidate['p'];
    result.add(MotionPathStop(progress: progress is num ? progress.toDouble() : 0, value: candidate['v']));
  }
  return List<MotionPathStop>.unmodifiable(result);
}

List<MotionPathStop> stopsFromTrack(MotionPathTrack track) {
  final values = <MotionPathStop>[];
  for (final entry in track.keyframes.entries) {
    final stops = stopsFromKeyframe(entry.value);
    if (stops.isNotEmpty) values.addAll(stops);
  }
  return values;
}
