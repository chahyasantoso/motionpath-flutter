import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Canvas, Color, Paint, Rect, Size;

import 'package:flutter/foundation.dart' show immutable, mapEquals;
import 'package:flutter/rendering.dart' show CustomPainter;

/// Default diagnostic fill, expressed as plain ARGB data so the renderer
/// boundary never depends on framework colour helpers.
const int kMotionPathDefaultArgb = 0xFF2196F3;

/// Renderer-neutral view over a composed MotionPath patch.
///
/// A patch is plain Dart data produced by `motionpath_core`. This type is the
/// only place that decides how those keys map onto Flutter painting concepts,
/// which keeps the pure Dart core free of any rendering knowledge.
@immutable
class MotionPathPatchTransform {
  /// Creates a resolved transform.
  const MotionPathPatchTransform({
    this.translateX = 0,
    this.translateY = 0,
    this.rotation = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.opacity = 1,
    this.argb = kMotionPathDefaultArgb,
  });

  /// Reads the renderer-neutral keys from [patch].
  ///
  /// Unknown keys are ignored, and missing keys fall back to identity values.
  factory MotionPathPatchTransform.fromPatch(
    Map<String, Object?> patch, {
    int fallbackArgb = kMotionPathDefaultArgb,
  }) {
    final double scale = _read(patch, const <String>['scale'], 1.0);
    final Object? color = patch['color'];
    return MotionPathPatchTransform(
      translateX: _read(patch, const <String>['x', 'translateX'], 0.0),
      translateY: _read(patch, const <String>['y', 'translateY'], 0.0),
      rotation: _read(patch, const <String>['rotation', 'rotate'], 0.0),
      scaleX: _read(patch, const <String>['scaleX'], scale),
      scaleY: _read(patch, const <String>['scaleY'], scale),
      opacity: _clamp01(_read(patch, const <String>['opacity'], 1.0)),
      argb: color is int ? color : fallbackArgb,
    );
  }

  /// Horizontal translation in logical pixels.
  final double translateX;

  /// Vertical translation in logical pixels.
  final double translateY;

  /// Rotation around the origin in radians.
  final double rotation;

  /// Horizontal scale factor.
  final double scaleX;

  /// Vertical scale factor.
  final double scaleY;

  /// Normalized opacity in `[0, 1]`.
  final double opacity;

  /// Fill colour as packed ARGB data.
  final int argb;

  /// Fill colour with [opacity] folded into the alpha channel.
  Color get color {
    final int sourceAlpha = (argb >> 24) & 0xFF;
    int alpha = (sourceAlpha * opacity).round();
    if (alpha < 0) {
      alpha = 0;
    } else if (alpha > 255) {
      alpha = 255;
    }
    return Color.fromARGB(
      alpha,
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
    );
  }

  /// Column-major 4x4 storage for scale, then rotate, then translate.
  ///
  /// Exposed so transform math can be asserted without a canvas.
  Float64List toMatrix4Storage() {
    final double cos = math.cos(rotation);
    final double sin = math.sin(rotation);
    final Float64List storage = Float64List(16);
    storage[0] = cos * scaleX;
    storage[1] = sin * scaleX;
    storage[4] = -sin * scaleY;
    storage[5] = cos * scaleY;
    storage[10] = 1;
    storage[12] = translateX;
    storage[13] = translateY;
    storage[15] = 1;
    return storage;
  }

  static double _clamp01(double value) {
    if (value.isNaN) {
      return 0;
    }
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  static double _read(
    Map<String, Object?> patch,
    List<String> keys,
    double fallback,
  ) {
    for (final String key in keys) {
      final Object? value = patch[key];
      if (value is num) {
        return value.toDouble();
      }
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) =>
      other is MotionPathPatchTransform &&
      other.translateX == translateX &&
      other.translateY == translateY &&
      other.rotation == rotation &&
      other.scaleX == scaleX &&
      other.scaleY == scaleY &&
      other.opacity == opacity &&
      other.argb == argb;

  @override
  int get hashCode => Object.hash(
        translateX,
        translateY,
        rotation,
        scaleX,
        scaleY,
        opacity,
        argb,
      );
}

/// Paints a composed MotionPath patch onto a canvas.
///
/// This is intentionally a focused renderer boundary: it draws one diagnostic
/// square so transform, opacity, and invalidation behaviour can be verified
/// before the Walker renderer and production scene widgets exist.
class MotionPathPatchPainter extends CustomPainter {
  /// Creates a painter for a single composed [patch].
  ///
  /// Pass `repaint` to drive invalidation straight from a patch source instead
  /// of rebuilding the widget that owns this painter.
  MotionPathPatchPainter({
    required this.patch,
    this.fallbackArgb = kMotionPathDefaultArgb,
    this.extent = 80,
    super.repaint,
  });

  /// The composed, renderer-neutral patch to draw.
  final Map<String, Object?> patch;

  /// Colour used when the patch carries no `color` key.
  final int fallbackArgb;

  /// Side length of the diagnostic square in logical pixels.
  final double extent;

  @override
  void paint(Canvas canvas, Size size) {
    final MotionPathPatchTransform transform =
        MotionPathPatchTransform.fromPatch(patch, fallbackArgb: fallbackArgb);
    final Paint fill = Paint()..color = transform.color;
    final double half = extent / 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.transform(transform.toMatrix4Storage());
    canvas.drawRect(Rect.fromLTWH(-half, -half, extent, extent), fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MotionPathPatchPainter oldDelegate) =>
      oldDelegate.extent != extent ||
      oldDelegate.fallbackArgb != fallbackArgb ||
      !mapEquals<String, Object?>(oldDelegate.patch, patch);
}
