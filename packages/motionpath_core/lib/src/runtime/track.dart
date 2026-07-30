import '../contract/motionpath_types.dart';
import '../interpolation/interpolator.dart';

class MotionPathTrackRuntime {
  MotionPathTrackRuntime(this.id, {Map<String, List<MotionPathStop>>? properties, List<MotionPathStop>? stops})
      : stops = stops ?? const <MotionPathStop>[],
        properties = properties ?? (stops == null ? const <String, List<MotionPathStop>>{} : <String, List<MotionPathStop>>{'value': stops});

  final String id;
  final List<MotionPathStop> stops;
  final Map<String, List<MotionPathStop>> properties;
  double progress = 0;
  final List<void Function(Map<String, Object?>)> _listeners = <void Function(Map<String, Object?>)>[];

  Map<String, Object?> compose({Map<String, Object?> inputs = const <String, Object?>{}}) {
    final patch = <String, Object?>{};
    patch.addAll(inputs);
    for (final entry in properties.entries) patch[entry.key] = interpolateStops(entry.value, progress);
    patch['progress'] = progress;
    return patch;
  }

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

Map<String, List<MotionPathStop>> propertiesFromTrack(MotionPathTrack track) {
  final result = <String, List<MotionPathStop>>{};
  for (final entry in track.keyframes.entries) {
    final keyframeStops = stopsFromKeyframe(entry.value);
    if (keyframeStops.isNotEmpty) result[entry.key] = keyframeStops;
  }
  return result;
}
