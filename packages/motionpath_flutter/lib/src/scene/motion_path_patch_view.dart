import 'dart:ui' show BlendMode, Color, ColorFilter, ImageFilter;

import 'package:flutter/widgets.dart';

import '../consumers/motion_path_patch_consumers.dart';
import '../painters/motion_path_patch_painter.dart';
import 'motion_path_patch_source.dart';

typedef MotionPathImageFrameBuilder = Widget Function(BuildContext context, Object frame);
typedef MotionPathCssVariablesBuilder = Widget Function(BuildContext context, Map<String, Object?> variables, Widget child);
typedef MotionPathInstancesBuilder = Widget Function(BuildContext context, List<Map<String, Object?>> instances, Widget child);

const ColorFilter _kIdentityColorFilter = ColorFilter.mode(Color(0x00000000), BlendMode.dst);

/// Applies one track's composed patch to a reusable Flutter child.
class MotionPathPatchView extends StatelessWidget {
  const MotionPathPatchView({required this.source, required this.trackId, this.child, this.size = const Size(200, 200), this.extent = 80, this.fallbackArgb = kMotionPathDefaultArgb, this.useDiagnosticPainter = false, this.imageFrameBuilder, this.cssVariablesBuilder, this.instancesBuilder, super.key});
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
          return CustomPaint(size: size, painter: MotionPathPatchPainter(patch: patch, fallbackArgb: fallbackArgb, extent: extent));
        }
        final MotionPathPatchTransform transform = MotionPathPatchTransform.fromPatch(patch, fallbackArgb: fallbackArgb);
        Widget result = stableChild;
        final Object? frame = MotionPathPatchConsumers.imageFrame(patch);
        if (frame != null && imageFrameBuilder != null) result = imageFrameBuilder!(context, frame);
        if (cssVariablesBuilder != null) result = cssVariablesBuilder!(context, MotionPathPatchConsumers.cssVariables(patch), result);
        if (instancesBuilder != null) result = instancesBuilder!(context, MotionPathPatchConsumers.instances(patch), result);
        final Object? visible = patch['visible'];
        result = Offstage(offstage: visible is bool && !visible, child: result);
        result = ImageFiltered(imageFilter: MotionPathPatchConsumers.blurFilter(patch) ?? ImageFilter.blur(sigmaX: 0, sigmaY: 0), child: result);
        result = Opacity(opacity: transform.opacity, child: result);
        result = Transform(
          alignment: Alignment.center,
          transform: Matrix4.fromList(transform.toMatrix4Storage()),
          child: result,
        );
        result = ColorFiltered(
          colorFilter: patch.containsKey('color') ? ColorFilter.mode(Color(transform.argb), BlendMode.modulate) : _kIdentityColorFilter,
          child: result,
        );
        return result;
      },
    );
  }
}
