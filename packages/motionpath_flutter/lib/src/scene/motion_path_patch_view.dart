import 'dart:ui' show ImageFilter, Offset;

import 'package:flutter/widgets.dart';

import '../consumers/motion_path_patch_consumers.dart';
import '../painters/motion_path_patch_painter.dart';
import 'motion_path_patch_source.dart';

/// Applies one track's composed patch to a reusable Flutter child.
///
/// The child is built once and reused by [AnimatedBuilder.child]. The wrapper
/// hierarchy stays stable across patch updates, so changing visual values does
/// not remount the child element.
class MotionPathPatchView extends StatelessWidget {
  /// Creates a view bound to [trackId] inside [source].
  const MotionPathPatchView({
    required this.source,
    required this.trackId,
    this.child,
    this.size = const Size(200, 200),
    this.extent = 80,
    this.fallbackArgb = kMotionPathDefaultArgb,
    this.useDiagnosticPainter = false,
    super.key,
  });

  final MotionPathPatchSource source;
  final String trackId;
  final Widget? child;
  final Size size;
  final double extent;
  final int fallbackArgb;
  final bool useDiagnosticPainter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: source,
      child: child,
      builder: (BuildContext context, Widget? stableChild) {
        final Map<String, Object?> patch = source.patchFor(trackId);
        if (useDiagnosticPainter || stableChild == null) {
          return CustomPaint(
            size: size,
            painter: MotionPathPatchPainter(
              patch: patch,
              fallbackArgb: fallbackArgb,
              extent: extent,
            ),
          );
        }
        final MotionPathPatchTransform transform =
            MotionPathPatchTransform.fromPatch(
              patch,
              fallbackArgb: fallbackArgb,
            );
        final ImageFilter filter =
            MotionPathPatchConsumers.blurFilter(patch) ??
            ImageFilter.blur(sigmaX: 0, sigmaY: 0);
        return Opacity(
          opacity: transform.opacity,
          child: Transform.translate(
            offset: Offset(transform.translateX, transform.translateY),
            child: Transform.rotate(
              angle: transform.rotationRadians,
              child: Transform.scale(
                scaleX: transform.scaleX,
                scaleY: transform.scaleY,
                child: ImageFiltered(imageFilter: filter, child: stableChild),
              ),
            ),
          ),
        );
      },
    );
  }
}
