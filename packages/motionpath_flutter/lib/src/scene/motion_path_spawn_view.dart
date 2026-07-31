import 'dart:ui' show ImageFilter, Offset;

import 'package:flutter/widgets.dart';

import '../consumers/motion_path_patch_consumers.dart';
import '../controllers/motion_path_spawn_controller.dart';
import '../painters/motion_path_patch_painter.dart';

/// Builds one stable child for each live spawned instance.
typedef MotionPathSpawnItemBuilder =
    Widget Function(BuildContext context, MotionPathSpawnInstance instance);

/// Renders dynamic children from composed spawn patches.
///
/// Controller snapshots remain in ascending-offset order for compatibility.
/// Flutter paints the ascending list directly, putting the higher-offset
/// top-most item last in the Stack. Use [motionPathTopMostFirst] when hit-test
/// traversal needs the front-most child first.
class MotionPathSpawnView extends StatelessWidget {
  const MotionPathSpawnView({
    required this.controller,
    required this.itemBuilder,
    this.alignment = Alignment.topLeft,
    this.fallbackArgb = kMotionPathDefaultArgb,
    super.key,
  });

  final MotionPathSpawnController controller;
  final MotionPathSpawnItemBuilder itemBuilder;
  final Alignment alignment;
  final int fallbackArgb;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          alignment: alignment,
          children: <Widget>[
            for (final MotionPathSpawnInstance instance in controller.instances)
              KeyedSubtree(
                key: ValueKey<String>(instance.id),
                child: _MotionPathSpawnItem(
                  instance: instance,
                  fallbackArgb: fallbackArgb,
                  child: itemBuilder(context, instance),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MotionPathSpawnItem extends StatelessWidget {
  const _MotionPathSpawnItem({required this.instance, required this.fallbackArgb, required this.child});
  final MotionPathSpawnInstance instance;
  final int fallbackArgb;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MotionPathPatchTransform transform = MotionPathPatchTransform.fromPatch(instance.patch, fallbackArgb: fallbackArgb);
    Widget result = child;
    if (transform.opacity != 1) result = Opacity(opacity: transform.opacity, child: result);
    final ImageFilter? filter = MotionPathPatchConsumers.blurFilter(instance.patch);
    if (filter != null) result = ImageFiltered(imageFilter: filter, child: result);
    if (transform.scaleX != 1 || transform.scaleY != 1) result = Transform.scale(scaleX: transform.scaleX, scaleY: transform.scaleY, child: result);
    if (transform.rotationRadians != 0) result = Transform.rotate(angle: transform.rotationRadians, child: result);
    if (transform.translateX != 0 || transform.translateY != 0) result = Transform.translate(offset: Offset(transform.translateX, transform.translateY), child: result);
    return result;
  }
}
