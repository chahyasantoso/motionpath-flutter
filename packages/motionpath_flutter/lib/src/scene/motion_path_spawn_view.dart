import 'dart:ui' show ImageFilter, Offset;

import 'package:flutter/widgets.dart';

import '../consumers/motion_path_patch_consumers.dart';
import '../controllers/motion_path_spawn_controller.dart';
import '../painters/motion_path_patch_painter.dart';

typedef MotionPathSpawnItemBuilder =
    Widget Function(BuildContext context, MotionPathSpawnInstance instance);
typedef MotionPathSpawnHitTest = bool Function(
  MotionPathSpawnInstance instance,
  Offset localPosition,
);

/// Renders dynamic children from composed spawn patches.
///
/// [onHit] is called for the front-most matching instance. The callback owns
/// the actual removal or interaction decision, so the generic host never
/// guesses at scene-specific hit geometry.
class MotionPathSpawnView extends StatelessWidget {
  const MotionPathSpawnView({
    required this.controller,
    required this.itemBuilder,
    this.alignment = Alignment.topLeft,
    this.fallbackArgb = kMotionPathDefaultArgb,
    this.onHit,
    super.key,
  });

  final MotionPathSpawnController controller;
  final MotionPathSpawnItemBuilder itemBuilder;
  final Alignment alignment;
  final int fallbackArgb;
  final MotionPathSpawnHitTest? onHit;

  @override
  Widget build(BuildContext context) {
    final Widget stack = AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          alignment: alignment,
          children: <Widget>[
            for (final MotionPathSpawnInstance instance in controller.instances)
              _MotionPathSpawnItem(
                key: ValueKey<String>(instance.id),
                instance: instance,
                fallbackArgb: fallbackArgb,
                child: itemBuilder(context, instance),
              ),
          ],
        );
      },
    );
    final MotionPathSpawnHitTest? hitTest = onHit;
    if (hitTest == null) return stack;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (TapUpDetails details) {
        motionPathHitTest(
          controller.instances,
          (MotionPathSpawnInstance instance) =>
              hitTest(instance, details.localPosition),
        );
      },
      child: stack,
    );
  }
}

class _MotionPathSpawnItem extends StatefulWidget {
  const _MotionPathSpawnItem({
    required this.instance,
    required this.fallbackArgb,
    required this.child,
    super.key,
  });

  final MotionPathSpawnInstance instance;
  final int fallbackArgb;
  final Widget child;

  @override
  State<_MotionPathSpawnItem> createState() => _MotionPathSpawnItemState();
}

class _MotionPathSpawnItemState extends State<_MotionPathSpawnItem> {
  late final Widget _stableChild = widget.child;

  @override
  Widget build(BuildContext context) {
    final MotionPathPatchTransform transform =
        MotionPathPatchTransform.fromPatch(
      widget.instance.patch,
      fallbackArgb: widget.fallbackArgb,
    );
    Widget result = _stableChild;
    if (transform.opacity != 1) {
      result = Opacity(opacity: transform.opacity, child: result);
    }
    final ImageFilter? filter = MotionPathPatchConsumers.blurFilter(
      widget.instance.patch,
    );
    if (filter != null) {
      result = ImageFiltered(imageFilter: filter, child: result);
    }
    if (transform.scaleX != 1 || transform.scaleY != 1) {
      result = Transform.scale(
        scaleX: transform.scaleX,
        scaleY: transform.scaleY,
        child: result,
      );
    }
    if (transform.rotationRadians != 0) {
      result = Transform.rotate(angle: transform.rotationRadians, child: result);
    }
    if (transform.translateX != 0 || transform.translateY != 0) {
      result = Transform.translate(
        offset: Offset(transform.translateX, transform.translateY),
        child: result,
      );
    }
    return result;
  }
}
