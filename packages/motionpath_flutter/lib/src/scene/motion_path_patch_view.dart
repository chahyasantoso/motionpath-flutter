import 'dart:ui' show ImageFilter, Offset;

import 'package:flutter/widgets.dart';

import '../consumers/motion_path_patch_consumers.dart';
import '../painters/motion_path_patch_painter.dart';
import 'motion_path_patch_source.dart';

/// Builds a widget for a resolved image-frame payload.
typedef MotionPathImageFrameBuilder = Widget Function(
  BuildContext context,
  Object frame,
);

/// Observes typed CSS custom-property data at the host boundary.
typedef MotionPathCssVariablesBuilder = Widget Function(
  BuildContext context,
  Map<String, Object?> variables,
  Widget child,
);

/// Observes normalized spawned-instance payloads at the host boundary.
typedef MotionPathInstancesBuilder = Widget Function(
  BuildContext context,
  List<Map<String, Object?>> instances,
  Widget child,
);

/// Applies one track's composed patch to a reusable Flutter child.
///
/// The child is built once and reused by [AnimatedBuilder.child]. The wrapper
/// hierarchy stays stable across patch updates, so changing visual values does
/// not remount the child element. Resource resolution remains host-owned via
/// the optional image, CSS, and instance builders.
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

        final ImageFilter? blur =
            MotionPathPatchConsumers.blurFilter(patch);
        if (blur != null) {
          result = ImageFiltered(imageFilter: blur, child: result);
        }
        if (transform.argb != fallbackArgb) {
          result = ColorFiltered(
            colorFilter: ColorFilter.mode(transform.color, BlendMode.modulate),
            child: result,
          );
        }
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
        final Object? visible = patch['visible'];
        if (visible is bool && !visible) {
          result = const Offstage(child: SizedBox.shrink());
        }
        return result;
      },
    );
  }
}
