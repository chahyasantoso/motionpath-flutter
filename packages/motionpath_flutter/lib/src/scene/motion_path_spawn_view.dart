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
class MotionPathSpawnView extends StatefulWidget {
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
  State<MotionPathSpawnView> createState() => _MotionPathSpawnViewState();
}

class _MotionPathSpawnViewState extends State<MotionPathSpawnView> {
  final Map<String, Widget> _children = <String, Widget>{};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_pruneDrainedChildren);
  }

  @override
  void didUpdateWidget(MotionPathSpawnView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_pruneDrainedChildren);
      widget.controller.addListener(_pruneDrainedChildren);
      _children.clear();
    } else if (!identical(oldWidget.itemBuilder, widget.itemBuilder)) {
      // Cached widgets close over the builder that created them. Reusing them
      // after a builder swap silently keeps the old host contract alive.
      _children.clear();
    }
  }

  /// Drops cached subtrees for instances the controller has drained.
  ///
  /// This runs on the controller notification rather than inside the
  /// [AnimatedBuilder] callback so the cache is never mutated during build.
  void _pruneDrainedChildren() {
    if (_children.isEmpty) return;
    final Set<String> liveIds = <String>{
      for (final MotionPathSpawnInstance instance
          in widget.controller.instances)
        instance.id,
    };
    _children.removeWhere((String id, Widget child) => !liveIds.contains(id));
  }

  Widget _childFor(MotionPathSpawnInstance instance, BuildContext context) {
    return _children.putIfAbsent(
      instance.id,
      () => KeyedSubtree(
        key: ValueKey<String>('motion-path-spawn-${instance.id}'),
        child: widget.itemBuilder(context, instance),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_pruneDrainedChildren);
    _children.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget stack = AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          alignment: widget.alignment,
          children: <Widget>[
            for (final MotionPathSpawnInstance instance
                in motionPathPaintOrder(widget.controller.instances))
              _MotionPathSpawnItem(
                key: ValueKey<String>(instance.id),
                instance: instance,
                fallbackArgb: widget.fallbackArgb,
                child: _childFor(instance, context),
              ),
          ],
        );
      },
    );
    final MotionPathSpawnHitTest? hitTest = widget.onHit;
    if (hitTest == null) return stack;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (TapUpDetails details) {
        motionPathHitTest(
          widget.controller.instances,
          (MotionPathSpawnInstance instance) =>
              hitTest(instance, details.localPosition),
        );
      },
      child: stack,
    );
  }
}

class _MotionPathSpawnItem extends StatelessWidget {
  const _MotionPathSpawnItem({
    required this.instance,
    required this.fallbackArgb,
    required this.child,
    super.key,
  });

  /// Stand-in used while [ImageFiltered] is disabled, so the filter keeps its
  /// slot in the element tree instead of appearing and disappearing.
  static final ImageFilter _inertFilter = ImageFilter.blur();

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
    final ImageFilter? filter = MotionPathPatchConsumers.blurFilter(
      instance.patch,
    );
    // Every wrapper below is unconditional and stays mounted for the life of
    // the instance. A conditional wrapper changes the shape of the element
    // tree between frames, which forces Flutter to deactivate and re-inflate
    // the spawned subtree and silently destroys any State it holds.
    //
    // Transform carries the full composed matrix, which reproduces the former
    // translate/rotate/scale chain exactly: the matrix is T * R * S and the
    // pure translation commutes with the center alignment, leaving rotation
    // and scale about the center and translation in parent space.
    //
    // Opacity at 1 skips its layer, and a disabled ImageFiltered skips its
    // own, so an untransformed instance costs nothing extra to paint.
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.fromFloat64List(transform.toMatrix4Storage()),
      child: Opacity(
        opacity: transform.opacity,
        child: ImageFiltered(
          enabled: filter != null,
          imageFilter: filter ?? _inertFilter,
          child: child,
        ),
      ),
    );
  }
}
