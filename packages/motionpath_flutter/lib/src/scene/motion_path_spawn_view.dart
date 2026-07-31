import 'dart:ui' show ImageFilter, Offset;

import 'package:flutter/widgets.dart';

import '../consumers/motion_path_patch_consumers.dart';
import '../controllers/motion_path_spawn_controller.dart';
import '../painters/motion_path_patch_painter.dart';

/// Builds one stable child for each live spawned instance.
typedef MotionPathSpawnItemBuilder = Widget Function(
  BuildContext context,
  MotionPathSpawnInstance instance,
);

/// Renders dynamic children from composed spawn patches.
///
/// The controller remains the only clock consumer. This widget only listens to
/// its snapshots, sorts instances by settled offset, assigns stable identity,
/// and applies the shared patch transform to each child.
class MotionPathSpawnView extends StatelessWidget {
  /// Creates a dynamic spawn view.
  const MotionPathSpawnView({
    required this.controller,
    required this.itemBuilder,
    this.alignment = Alignment.topLeft,
    this.fallbackArgb = kMotionPathDefaultArgb,
    super.key,
  });

  /// Dynamic child lifecycle and composed patch source.
  final MotionPathSpawnController controller;

  /// Builds the content inside each patch-driven instance wrapper.
  final MotionPathSpawnItemBuilder itemBuilder;

  /// Stack alignment for children whose patches do not translate them.
  final Alignment alignment;

  /// Fallback color for consumers that inspect color through the shared resolver.
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
  const _MotionPathSpawnItem({
    required this.instance,
    required this.fallbackArgb,
    required this.child,
  });

  final MotionPathSpawnInstance instance;
  final int fallbackArgb;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MotionPathPatchTransform transform =
        MotionPathPatchTransform.fromPatch(
      instance.patch,
      fallbackArgb: fallbackArgb,
    );
    Widget result = child;
    if (transform.opacity != 1) {
      result = Opacity(opacity: transform.opacity, child: result);
    }
    final ImageFilter? filter = MotionPathPatchConsumers.blurFilter(instance.patch);
    if (filter != null) {
      result = ImageFiltered(imageFilter: filter, child: result);
    }
    result = Transform(
      alignment: Alignment.center,
      transform: transform.toMatrix4Storage().toMatrix4(),
      child: result,
    );
    if (transform.translateX != 0 || transform.translateY != 0) {
      result = Transform.translate(
        offset: Offset(transform.translateX, transform.translateY),
        child: result,
      );
    }
    return result;
  }
}

extension on List<double> {
  Matrix4 toMatrix4() => Matrix4.fromList(this);
}
