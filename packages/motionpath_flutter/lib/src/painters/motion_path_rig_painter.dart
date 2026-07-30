import 'dart:ui'
    show Canvas, Color, Offset, Paint, PaintingStyle, Size, StrokeCap;

import 'package:flutter/foundation.dart' show immutable, listEquals, mapEquals;
import 'package:flutter/rendering.dart' show CustomPainter;

/// One rig connection between a parent joint and its child joint.
@immutable
class MotionPathBone {
  /// Creates a bone.
  const MotionPathBone({required this.parent, required this.child});

  /// Track id of the parent joint.
  final String parent;

  /// Track id of the child joint.
  final String child;

  @override
  bool operator ==(Object other) =>
      other is MotionPathBone && other.parent == parent && other.child == child;

  @override
  int get hashCode => Object.hash(parent, child);
}

/// Draws a forward-kinematics rig from composed patches.
///
/// The painter reads world `x` and `y` straight out of each patch. All rig math
/// already happened in the pure Dart core, so a bone can never draw one length
/// while its child observes another.
class MotionPathRigPainter extends CustomPainter {
  /// Creates a rig painter.
  MotionPathRigPainter({
    required this.patches,
    required this.bones,
    this.origin = Offset.zero,
    this.color = const Color(0xFF111111),
    this.strokeWidth = 4,
    this.jointRadius = 3,
  });

  /// Composed patches keyed by track id.
  final Map<String, Map<String, Object?>> patches;

  /// Bones to draw, in draw order.
  final List<MotionPathBone> bones;

  /// Offset applied to every joint, usually the scene origin.
  final Offset origin;

  /// Bone and joint colour.
  final Color color;

  /// Bone stroke width in logical pixels.
  final double strokeWidth;

  /// Joint dot radius in logical pixels.
  final double jointRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Paint fill = Paint()..color = color;

    for (final MotionPathBone bone in bones) {
      final Offset? from = jointFor(bone.parent);
      final Offset? to = jointFor(bone.child);
      if (from == null || to == null) {
        continue;
      }
      canvas.drawLine(from + origin, to + origin, stroke);
      canvas.drawCircle(from + origin, jointRadius, fill);
      canvas.drawCircle(to + origin, jointRadius, fill);
    }
  }

  /// World position of one joint, or null when the patch carries no position.
  Offset? jointFor(String trackId) {
    final Map<String, Object?>? patch = patches[trackId];
    if (patch == null) {
      return null;
    }
    final Object? x = patch['x'];
    final Object? y = patch['y'];
    if (x is! num || y is! num) {
      return null;
    }
    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  bool shouldRepaint(covariant MotionPathRigPainter oldDelegate) =>
      oldDelegate.origin != origin ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.jointRadius != jointRadius ||
      !listEquals<MotionPathBone>(oldDelegate.bones, bones) ||
      !_patchesEqual(oldDelegate.patches, patches);
}

bool _patchesEqual(
  Map<String, Map<String, Object?>> a,
  Map<String, Map<String, Object?>> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (final MapEntry<String, Map<String, Object?>> entry in a.entries) {
    final Map<String, Object?>? other = b[entry.key];
    if (other == null || !mapEquals<String, Object?>(entry.value, other)) {
      return false;
    }
  }
  return true;
}
