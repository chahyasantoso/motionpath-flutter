import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Canvas, Color, Paint, Rect, Size;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/rendering.dart' show CustomPainter;

import '../consumers/motion_path_patch_equality.dart';

/// Default diagnostic fill, expressed as plain ARGB data so the renderer
/// boundary never depends on framework colour helpers.
const int kMotionPathDefaultArgb = 0xFF2196F3;

/// Renderer-neutral view over a composed MotionPath patch.
@immutable
class MotionPathPatchTransform {
  const MotionPathPatchTransform({
    this.translateX = 0,
    this.translateY = 0,
    this.translateZ = 0,
    this.rotation = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.scaleZ = 1,
    this.perspective = 0,
    this.opacity = 1,
    this.argb = kMotionPathDefaultArgb,
  });

  /// Reads renderer-neutral keys. Rotations are authored in degrees.
  factory MotionPathPatchTransform.fromPatch(
    Map<String, Object?> patch, {
    int fallbackArgb = kMotionPathDefaultArgb,
  }) {
    final double scale = _read(patch, const <String>['scale'], 1.0);
    final Object? color = patch['color'];
    return MotionPathPatchTransform(
      translateX: _read(patch, const <String>['x', 'translateX'], 0.0),
      translateY: _read(patch, const <String>['y', 'translateY'], 0.0),
      translateZ: _read(patch, const <String>['z', 'translateZ'], 0.0),
      rotation: _read(patch, const <String>['rotation', 'rotate'], 0.0),
      rotationX: _read(patch, const <String>['rotationX', 'rotateX'], 0.0),
      rotationY: _read(patch, const <String>['rotationY', 'rotateY'], 0.0),
      scaleX: _read(patch, const <String>['scaleX'], scale),
      scaleY: _read(patch, const <String>['scaleY'], scale),
      scaleZ: _read(patch, const <String>['scaleZ'], scale),
      perspective: _read(patch, const <String>['perspective'], 0.0),
      opacity: _clamp01(_read(patch, const <String>['opacity'], 1.0)),
      argb: color is int ? color : fallbackArgb,
    );
  }

  final double translateX;
  final double translateY;
  final double translateZ;
  final double rotation;
  final double rotationX;
  final double rotationY;
  final double scaleX;
  final double scaleY;
  final double scaleZ;
  final double perspective;
  final double opacity;
  final int argb;

  double get rotationRadians => _radians(rotation);
  double get rotationXRadians => _radians(rotationX);
  double get rotationYRadians => _radians(rotationY);

  Color get color {
    final int sourceAlpha = (argb >> 24) & 0xFF;
    final int alpha = (sourceAlpha * opacity).round().clamp(0, 255);
    return Color.fromARGB(alpha, (argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);
  }

  /// Column-major 4x4 storage for perspective, scale, XYZ rotation, translation.
  Float64List toMatrix4Storage() {
    final Float64List storage = Float64List(16);
    final double rz = rotationXRadians;
    final double ry = rotationYRadians;
    final double r = rotationRadians;
    final double cx = math.cos(rz), sx = math.sin(rz);
    final double cy = math.cos(ry), sy = math.sin(ry);
    final double cz = math.cos(r), sz = math.sin(r);
    // Rz * Ry * Rx, with scale applied on the local axes.
    storage[0] = (cz * cy) * scaleX;
    storage[1] = (sz * cy) * scaleX;
    storage[2] = (-sy) * scaleX;
    storage[4] = (cz * sy * sx - sz * cx) * scaleY;
    storage[5] = (sz * sy * sx + cz * cx) * scaleY;
    storage[6] = (cy * sx) * scaleY;
    storage[8] = (cz * sy * cx + sz * sx) * scaleZ;
    storage[9] = (sz * sy * cx - cz * sx) * scaleZ;
    storage[10] = (cy * cx) * scaleZ;
    if (perspective != 0 && perspective.isFinite) {
      storage[11] = -perspective;
    }
    storage[12] = translateX;
    storage[13] = translateY;
    storage[14] = translateZ;
    storage[15] = 1;
    return storage;
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
  static double _clamp01(double value) => value.isNaN ? 0 : value.clamp(0.0, 1.0).toDouble();
  static double _read(Map<String, Object?> patch, List<String> keys, double fallback) {
    for (final String key in keys) {
      final Object? value = patch[key];
      if (value is num && value.toDouble().isFinite) return value.toDouble();
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) => other is MotionPathPatchTransform &&
      other.translateX == translateX && other.translateY == translateY && other.translateZ == translateZ &&
      other.rotation == rotation && other.rotationX == rotationX && other.rotationY == rotationY &&
      other.scaleX == scaleX && other.scaleY == scaleY && other.scaleZ == scaleZ &&
      other.perspective == perspective && other.opacity == opacity && other.argb == argb;

  @override
  int get hashCode => Object.hash(translateX, translateY, translateZ, rotation, rotationX, rotationY, scaleX, scaleY, scaleZ, perspective, opacity, argb);
}

class MotionPathPatchPainter extends CustomPainter {
  MotionPathPatchPainter({required this.patch, this.fallbackArgb = kMotionPathDefaultArgb, this.extent = 80, super.repaint});
  final Map<String, Object?> patch;
  final int fallbackArgb;
  final double extent;

  @override
  void paint(Canvas canvas, Size size) {
    final MotionPathPatchTransform transform = MotionPathPatchTransform.fromPatch(patch, fallbackArgb: fallbackArgb);
    final Paint fill = Paint()..color = transform.color;
    final double half = extent / 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.transform(transform.toMatrix4Storage());
    canvas.drawRect(Rect.fromLTWH(-half, -half, extent, extent), fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MotionPathPatchPainter oldDelegate) => oldDelegate.extent != extent || oldDelegate.fallbackArgb != fallbackArgb || !motionPathPatchEquals(oldDelegate.patch, patch);
}
