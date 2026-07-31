import 'package:flutter/widgets.dart';

import '../painters/motion_path_patch_painter.dart';
import '../consumers/motion_path_patch_consumers.dart';
import 'motion_path_patch_source.dart';

/// Applies one track's composed patch to a reusable Flutter child.
///
/// The child is built once and reused by [AnimatedBuilder.child]. Patch updates
/// only rebuild the small transform/opacity wrapper, so expensive scene content
/// does not rebuild on every engine tick.
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

  /// Publishes composed patches.
  final MotionPathPatchSource source;

  /// Track whose patch drives this view.
  final String trackId;

  /// Expensive content to keep alive across patch updates.
  final Widget? child;

  /// Canvas size used by diagnostic fallback mode.
  final Size size;

  /// Diagnostic square side length.
  final double extent;

  /// Diagnostic fallback colour.
  final int fallbackArgb;

  /// Whether to render the diagnostic square instead of [child].
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
        Widget result = stableChild;
        if (transform.opacity != 1) {
          result = Opacity(opacity: transform.opacity, child: result);
        }
        if (transform.scaleX != 1 || transform.scaleY != 1) {
          result = Transform.scale(
            scaleX: transform.scaleX,
            scaleY: transform.scaleY,
            child: result,
          );
        }
        if (transform.rotationRadians != 0) {
          result = Transform.rotate(
            angle: transform.rotationRadians,
            child: result,
          );
        }
        if (transform.translateX != 0 || transform.translateY != 0) {
          result = Transform.translate(
            offset: Offset(transform.translateX, transform.translateY),
            child: result,
          );
        }
        final ImageFilter? filter = MotionPathPatchConsumers.blurFilter(patch);
        if (filter != null) {
          result = ImageFiltered(imageFilter: filter, child: result);
        }
        return result;
      },
    );
  }
}
