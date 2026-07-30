import 'dart:math' as math;

/// A plain 2D world transform.
///
/// Rotation is expressed in degrees to stay byte-compatible with the authored
/// v4 JSON, which is DOM-space: `+x` is right and `+y` is down.
class MotionPathWorldTransform {
  /// Creates a world transform.
  const MotionPathWorldTransform({this.x = 0, this.y = 0, this.rotation = 0});

  /// Reads `x`, `y`, and `rotation` out of a composed patch.
  ///
  /// Missing or non-numeric entries fall back to zero, which matches the
  /// reference runtime's nullish handling.
  factory MotionPathWorldTransform.fromPatch(Map<String, Object?>? patch) {
    if (patch == null) return const MotionPathWorldTransform();
    return MotionPathWorldTransform(
      x: _readNumber(patch['x']),
      y: _readNumber(patch['y']),
      rotation: _readNumber(patch['rotation']),
    );
  }

  /// Horizontal world position.
  final double x;

  /// Vertical world position.
  final double y;

  /// World rotation in degrees.
  final double rotation;

  /// The transform as a flat, renderer-neutral patch.
  Map<String, Object?> toPatch() => <String, Object?>{'x': x, 'y': y, 'rotation': rotation};

  @override
  bool operator ==(Object other) =>
      other is MotionPathWorldTransform && other.x == x && other.y == y && other.rotation == rotation;

  @override
  int get hashCode => Object.hash(x, y, rotation);

  @override
  String toString() => 'MotionPathWorldTransform(x: $x, y: $y, rotation: $rotation)';
}

double _readNumber(Object? value) => value is num ? value.toDouble() : 0;

/// Accumulates [local] onto [parentWorld] for forward kinematics.
///
/// This is the Dart port of `packages/core/src/math/fkMath.js`: the local offset
/// is rotated by the parent's world rotation, then translated, and rotations add.
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
