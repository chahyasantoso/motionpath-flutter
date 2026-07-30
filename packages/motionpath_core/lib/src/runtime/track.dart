import '../contract/motionpath_types.dart';
import '../interpolation/color_value.dart';
import '../interpolation/easing.dart';
import '../interpolation/interpolator.dart';

class MotionPathTrackRuntime {
  MotionPathTrackRuntime(this.id, {this.properties = const <String, List<MotionPathStop>>{}, this.stops = const <MotionPathStop>[]});
  final String id;
  final List<MotionPathStop> stops;
  final Map<String, List<MotionPathStop>> properties;
  double progress = 0;
  final List<void Function(Map<String, Object?>)> _listeners = <void Function(Map<String, Object?>)>[];

  Map<String, Object?> compose({Map<String, Object?> inputs = const <String, Object?>{}}) {
    final patch = <String, Object?>{};
    patch.addAll(inputs);
    final authored = properties.isEmpty && stops.isNotEmpty ? <String, List<MotionPathStop>>{'value': stops} : properties;
    for (final entry in authored.entries) {
      patch[entry.key] = interpolateStops(entry.value, progress, blend: blendForProperty(entry.key));
    }
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

/// Picks the value blend a property key needs.
///
/// Colour keys interpolate per channel; everything else uses the numeric and
/// switch-at-the-end default.
ValueBlend blendForProperty(String propertyKey) =>
    kMotionPathColorKeys.contains(propertyKey) ? blendColorValues : MotionPathInterpolators.value;

/// Reads the authored stops for one keyframe.
///
/// [propertyKey] decides whether stop values are normalized into packed ARGB
/// data. Each stop's `ease` wins over the keyframe-level `ease`, and an unknown
/// name degrades to linear.
List<MotionPathStop> stopsFromKeyframe(Object? raw, {String propertyKey = ''}) {
  if (raw is! Map) return const <MotionPathStop>[];
  final stops = raw['stops'];
  if (stops is! List) return const <MotionPathStop>[];
  final Easing keyframeEase = resolveEasing(raw['ease']);
  final bool isColor = kMotionPathColorKeys.contains(propertyKey);
  final result = <MotionPathStop>[];
  for (final candidate in stops) {
    if (candidate is! Map) continue;
    final progress = candidate['p'];
    final Object? value = candidate['v'];
    result.add(MotionPathStop(
      progress: progress is num ? progress.toDouble() : 0,
      value: isColor ? (parseColorArgb(value) ?? value) : value,
      ease: candidate.containsKey('ease') ? resolveEasing(candidate['ease']) : keyframeEase,
    ));
  }
  return List<MotionPathStop>.unmodifiable(result);
}

Map<String, List<MotionPathStop>> propertiesFromTrack(MotionPathTrack track) {
  final result = <String, List<MotionPathStop>>{};
  for (final entry in track.keyframes.entries) {
    final keyframeStops = stopsFromKeyframe(entry.value, propertyKey: entry.key);
    if (keyframeStops.isNotEmpty) result[entry.key] = keyframeStops;
  }
  return result;
}
