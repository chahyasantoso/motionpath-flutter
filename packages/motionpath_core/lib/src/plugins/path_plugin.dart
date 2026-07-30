import '../contract/motionpath_types.dart';
import '../math/fk_math.dart';
import 'motionpath_plugin.dart';

/// Samples a normalized polyline authored as `{x, y}` points.
///
/// The plugin reads `path` and `progress`, then emits renderer-neutral `x` and
/// `y`. A path with fewer than two valid points is ignored rather than guessed.
const MotionPathPlugin pathPlugin = MotionPathPlugin(
  name: 'path',
  keys: <String>['path'],
  inputs: <String>['progress'],
  outputs: <String>['x', 'y'],
  internalKeys: <String>['path'],
  stage: 20,
  compose: _composePath,
);

Map<String, Object?>? _composePath(Map<String, Object?> raw) {
  final List<MotionPathWorldTransform> points = _points(raw['path']);
  if (points.length < 2) {
    return null;
  }
  final double progress = raw['progress'] is num
      ? (raw['progress']! as num).toDouble().clamp(0.0, 1.0).toDouble()
      : 0;
  final double scaled = progress * (points.length - 1);
  final int index = scaled.floor().clamp(0, points.length - 2);
  final double local = scaled - index;
  final MotionPathWorldTransform from = points[index];
  final MotionPathWorldTransform to = points[index + 1];
  return <String, Object?>{
    'x': from.x + (to.x - from.x) * local,
    'y': from.y + (to.y - from.y) * local,
  };
}

List<MotionPathWorldTransform> _points(Object? raw) {
  if (raw is! List<Object?>) {
    return const <MotionPathWorldTransform>[];
  }
  final List<MotionPathWorldTransform> result = <MotionPathWorldTransform>[];
  for (final Object? value in raw) {
    final Map<String, Object?> point = asStringKeyedMap(value);
    if (point['x'] is num && point['y'] is num) {
      result.add(MotionPathWorldTransform(
        x: (point['x']! as num).toDouble(),
        y: (point['y']! as num).toDouble(),
      ));
    }
  }
  return result;
}
