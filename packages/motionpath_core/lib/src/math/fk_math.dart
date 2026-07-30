import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../contract/motionpath_types.dart';

/// A 2D world transform used by forward kinematics.
///
/// [rotation] is in degrees so the value stays interchangeable with the
/// JavaScript reference runtime and with authored keyframes. Renderers convert
/// to radians at the boundary.
@immutable
class MotionPathWorldTransform {
  /// Creates a transform.
  const MotionPathWorldTransform({
    this.x = 0,
    this.y = 0,
    this.rotation = 0,
  });

  /// Reads `x`, `y`, and `rotation` from a renderer-neutral patch.
  factory MotionPathWorldTransform.fromPatch(Map<String, Object?> patch) =>
      MotionPathWorldTransform(
        x: _readDouble(patch['x']),
        y: _readDouble(patch['y']),
        rotation: _readDouble(patch['rotation']),
      );

  /// Horizontal world position.
  final double x;

  /// Vertical world position.
  final double y;

  /// World rotation in degrees.
  final double rotation;

  /// Serializes back into a renderer-neutral patch fragment.
  Map<String, Object?> toPatch() => <String, Object?>{
        'x': x,
        'y': y,
        'rotation': rotation,
      };

  /// Distance to [other] in world space.
  double distanceTo(MotionPathWorldTransform other) {
    final double dx = other.x - x;
    final double dy = other.y - y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double _readDouble(Object? value) =>
      value is num ? value.toDouble() : 0.0;

  @override
  bool operator ==(Object other) =>
      other is MotionPathWorldTransform &&
      other.x == x &&
      other.y == y &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(x, y, rotation);

  @override
  String toString() =>
      'MotionPathWorldTransform(x: $x, y: $y, rotation: $rotation)';
}

/// Accumulates a child's world transform from its parent and local offset.
///
/// World rotation accumulates down the chain, so a joint's authored angle is
/// always local. This is the single place FK math lives; the renderer never
/// recomputes it.
MotionPathWorldTransform composeWorld(
  MotionPathWorldTransform parentWorld,
  MotionPathWorldTransform local,
) {
  final double radians = parentWorld.rotation * math.pi / 180;
  final double cos = math.cos(radians);
  final double sin = math.sin(radians);
  return MotionPathWorldTransform(
    x: parentWorld.x + (local.x * cos - local.y * sin),
    y: parentWorld.y + (local.x * sin + local.y * cos),
    rotation: parentWorld.rotation + local.rotation,
  );
}

/// Distance between two composed patches, for FK invariant assertions.
double patchDistance(Map<String, Object?> a, Map<String, Object?> b) =>
    MotionPathWorldTransform.fromPatch(a)
        .distanceTo(MotionPathWorldTransform.fromPatch(b));

/// Reads a world transform out of an observation input value.
MotionPathWorldTransform worldFromInput(Object? value) =>
    MotionPathWorldTransform.fromPatch(asStringKeyedMap(value));
