import 'dart:math' as math;

import '../contract/motionpath_types.dart';
import 'motionpath_plugin.dart';

/// Samples JS-compatible path waypoints by normalized physical distance.
///
/// Nodes accept `{x, y, z?, ctrlX?, ctrlY?, ctrlZ?}`. Controls describe the
/// quadratic segment ending at that node, matching the JavaScript reference.
const MotionPathPlugin pathPlugin = MotionPathPlugin(
  name: 'path',
  keys: <String>['path'],
  inputs: <String>['progress'],
  outputs: <String>['x', 'y', 'z'],
  internalKeys: <String>['path'],
  stage: 20,
  compose: _composePath,
);

Map<String, Object?>? _composePath(Map<String, Object?> raw) {
  final List<_PathNode> nodes = _nodes(raw['path']);
  if (nodes.length < 2) return null;
  final double progress = raw['progress'] is num
      ? (raw['progress']! as num).toDouble().clamp(0.0, 1.0).toDouble()
      : 0;
  return _samplePath(nodes, progress);
}

class _PathNode {
  const _PathNode({
    required this.x,
    required this.y,
    required this.z,
    this.ctrlX,
    this.ctrlY,
    this.ctrlZ,
  });

  final double x;
  final double y;
  final double z;
  final double? ctrlX;
  final double? ctrlY;
  final double? ctrlZ;

  bool get curved => ctrlX != null && ctrlY != null;
}

class _CubicSegment {
  const _CubicSegment(this.p0, this.p1, this.p2, this.p3, this.length);

  final _PathNode p0;
  final _PathNode p1;
  final _PathNode p2;
  final _PathNode p3;
  final double length;
}

List<_PathNode> _nodes(Object? raw) {
  if (raw is! List<Object?>) return const <_PathNode>[];
  final List<_PathNode> result = <_PathNode>[];
  for (final Object? value in raw) {
    final Map<String, Object?> point = asStringKeyedMap(value);
    if (point['x'] is! num || point['y'] is! num) continue;
    double? number(String key) =>
        point[key] is num ? (point[key]! as num).toDouble() : null;
    result.add(
      _PathNode(
        x: (point['x']! as num).toDouble(),
        y: (point['y']! as num).toDouble(),
        z: number('z') ?? 0,
        ctrlX: number('ctrlX'),
        ctrlY: number('ctrlY'),
        ctrlZ: number('ctrlZ'),
      ),
    );
  }
  return result;
}

Map<String, Object?> _samplePath(List<_PathNode> nodes, double progress) {
  final List<_CubicSegment> segments = <_CubicSegment>[];
  double totalLength = 0;
  for (int index = 1; index < nodes.length; index++) {
    final _PathNode start = nodes[index - 1];
    final _PathNode end = nodes[index];
    final _PathNode cp1;
    final _PathNode cp2;
    if (end.curved) {
      final double controlZ = end.ctrlZ ?? (start.z + end.z) / 2;
      cp1 = _PathNode(
        x: start.x + 2 / 3 * (end.ctrlX! - start.x),
        y: start.y + 2 / 3 * (end.ctrlY! - start.y),
        z: start.z + 2 / 3 * (controlZ - start.z),
      );
      cp2 = _PathNode(
        x: end.x + 2 / 3 * (end.ctrlX! - end.x),
        y: end.y + 2 / 3 * (end.ctrlY! - end.y),
        z: end.z + 2 / 3 * (controlZ - end.z),
      );
    } else {
      cp1 = _PathNode(
        x: start.x + (end.x - start.x) / 3,
        y: start.y + (end.y - start.y) / 3,
        z: start.z + (end.z - start.z) / 3,
      );
      cp2 = _PathNode(
        x: start.x + 2 * (end.x - start.x) / 3,
        y: start.y + 2 * (end.y - start.y) / 3,
        z: start.z + 2 * (end.z - start.z) / 3,
      );
    }
    final double length = _cubicLength(start, cp1, cp2, end);
    segments.add(_CubicSegment(start, cp1, cp2, end, length));
    totalLength += length;
  }
  if (totalLength == 0) {
    return <String, Object?>{
      'x': nodes.first.x,
      'y': nodes.first.y,
      'z': nodes.first.z,
    };
  }

  double target = progress * totalLength;
  for (int index = 0; index < segments.length; index++) {
    final _CubicSegment segment = segments[index];
    if (target <= segment.length || index == segments.length - 1) {
      final double localDistance = target.clamp(0, segment.length).toDouble();
      final double t = _parameterAtDistance(segment, localDistance);
      return _point(segment, t);
    }
    target -= segment.length;
  }
  return _point(segments.last, 1);
}

Map<String, Object?> _point(_CubicSegment segment, double t) {
  final double mt = 1 - t;
  final double mt2 = mt * mt;
  final double t2 = t * t;
  return <String, Object?>{
    'x':
        mt2 * mt * segment.p0.x +
        3 * mt2 * t * segment.p1.x +
        3 * mt * t2 * segment.p2.x +
        t2 * t * segment.p3.x,
    'y':
        mt2 * mt * segment.p0.y +
        3 * mt2 * t * segment.p1.y +
        3 * mt * t2 * segment.p2.y +
        t2 * t * segment.p3.y,
    'z':
        mt2 * mt * segment.p0.z +
        3 * mt2 * t * segment.p1.z +
        3 * mt * t2 * segment.p2.z +
        t2 * t * segment.p3.z,
  };
}

double _distance(_PathNode a, _PathNode b) {
  final double dx = b.x - a.x;
  final double dy = b.y - a.y;
  final double dz = b.z - a.z;
  return math.sqrt(dx * dx + dy * dy + dz * dz);
}

double _cubicLength(_PathNode p0, _PathNode p1, _PathNode p2, _PathNode p3) {
  const int samples = 64;
  final _CubicSegment segment = _CubicSegment(p0, p1, p2, p3, 0);
  double length = 0;
  _PathNode previous = p0;
  for (int index = 1; index <= samples; index++) {
    final Map<String, Object?> point = _point(segment, index / samples);
    final _PathNode current = _PathNode(
      x: point['x']! as double,
      y: point['y']! as double,
      z: point['z']! as double,
    );
    length += _distance(previous, current);
    previous = current;
  }
  return length;
}

double _parameterAtDistance(_CubicSegment segment, double distance) {
  const int samples = 64;
  if (distance <= 0) return 0;
  if (distance >= segment.length) return 1;
  double travelled = 0;
  _PathNode previous = segment.p0;
  for (int index = 1; index <= samples; index++) {
    final double t = index / samples;
    final Map<String, Object?> point = _point(segment, t);
    final _PathNode current = _PathNode(
      x: point['x']! as double,
      y: point['y']! as double,
      z: point['z']! as double,
    );
    final double step = _distance(previous, current);
    if (travelled + step >= distance) {
      final double fraction = step == 0 ? 0 : (distance - travelled) / step;
      return (index - 1 + fraction) / samples;
    }
    travelled += step;
    previous = current;
  }
  return 1;
}
