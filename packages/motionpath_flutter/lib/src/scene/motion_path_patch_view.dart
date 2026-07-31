import 'dart:ui' show BlendMode, Color, ColorFilter, ImageFilter, Offset;

import 'package:flutter/widgets.dart';

import '../consumers/motion_path_patch_consumers.dart';
import '../painters/motion_path_patch_painter.dart';
import 'motion_path_patch_source.dart';

typedef MotionPathImageFrameBuilder = Widget Function(
  BuildContext context,
  Object frame,
);
typedef MotionPathCssVariablesBuilder = Widget Function(
  BuildContext context,
  Map<String, Object?> variables,
  Widget child,
);
typedef MotionPathInstancesBuilder = Widget Function(
  BuildContext context,
  List<Map<String, Object?>> instances,
  Widget child,
);

/// Applies one track's composed patch to a reusable Flutter child.
class MotionPathPatchView extends StatelessWidget {
  const MotionPathPatchView({
    required this.source,
    required this.trackId,
    this.child,
    this.size = const Size(200, 200),
    this.extent = 80,
    this.fallbackArgb = kMotionPathDefaultArgb,
    this.useDiagnosticPainter = false,
    this.imageFrameBuilder,
    this.cssVariablesBuilder,
    this.instancesBuilder,
    super.key,
  });

  final MotionPathPatchSource source;
  final String trackId;
  final Widget? child;
  final Size size;
  final double extent;
  final int fallbackArgb;
  final bool useDiagnosticPainter;
  final MotionPathImageFrameBuilder? imageFrameBuilder;
  final MotionPathCssVariablesBuilder? cssVariablesBuilder;
  final MotionPathInstancesBuilder? instancesBuilder;

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
        final Object? frame = MotionPathPatchConsumers.imageFrame(patch);
        if (frame != null && imageFrameBuilder != null) {
          result = imageFrameBuilder!(context, frame);
        }
        if (cssVariablesBuilder != null) {
          result = cssVariablesBuilder!(
            context,
            MotionPathPatchConsumers.cssVariables(patch),
            result,
          );
        }
        if (instancesBuilder != null) {
          result = instancesBuilder!(
            context,
            MotionPathPatchConsumers.instances(patch),
            result,
          );
        }

        // Keep the transform/effect parent chain stable. Conditional wrappers
        // remount the supplied child when a patch changes from identity to an
        // animated value, defeating AnimatedBuilder.child reuse.
        result = ImageFiltered(
          imageFilter: MotionPathPatchConsumers.blurFilter(patch) ??
              ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: result,
        );
        result = Opacity(opacity: transform.opacity, child: result);
        result = Transform.scale(
          scaleX: transform.scaleX,
          scaleY: transform.scaleY,
          child: result,
        );
        result = Transform.rotate(
          angle: transform.rotationRadians,
          child: result,
        );
        result = Transform.translate(
          offset: Offset(transform.translateX, transform.translateY),
          child: result,
        );
        if (patch.containsKey('color')) {
          result = ColorFiltered(
            colorFilter: ColorFilter.mode(
              Color(transform.argb),
              BlendMode.modulate,
            ),
            child: result,
          );
        }
        final Object? visible = patch['visible'];
        if (visible is bool && !visible) {
          result = Offstage(child: result);
        }
        return result;
      },
    );
  }
}
