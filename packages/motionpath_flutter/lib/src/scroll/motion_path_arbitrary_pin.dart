import 'package:flutter/widgets.dart';

import '../bindings/motion_path_viewport_binding.dart';

/// Positions arbitrary viewport content from [MotionPathViewportSample].
///
/// Unlike `MotionPathPinnedHeader`, this host works inside a `Stack` and can
/// pin at the viewport's leading edge for any authored scroll window. The
/// binding owns sampling; this widget only listens and lays out the child.
///
/// Place it as a `Stack` child overlaying the scrollable, with the binding
/// attached to that scrollable's position. Offsets are measured from the
/// stack's leading edge, so the stack has to match the viewport.
class MotionPathArbitraryPinned extends StatefulWidget {
  /// Creates a pin host driven by [binding].
  const MotionPathArbitraryPinned({
    required this.binding,
    required this.child,
    this.alignment = Alignment.topLeft,
    super.key,
  });

  /// Sampling source for the pinned geometry.
  final MotionPathViewportBinding binding;

  /// Content laid out at the sampled paint offset.
  final Widget child;

  /// Alignment of [child] within the positioned band.
  final Alignment alignment;

  @override
  State<MotionPathArbitraryPinned> createState() =>
      _MotionPathArbitraryPinnedState();
}

class _MotionPathArbitraryPinnedState extends State<MotionPathArbitraryPinned> {
  late MotionPathViewportSample _painted;

  @override
  void initState() {
    super.initState();
    _painted = widget.binding.sample;
    widget.binding.addListener(_onSample);
  }

  @override
  void didUpdateWidget(covariant MotionPathArbitraryPinned oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.binding == widget.binding) return;
    oldWidget.binding.removeListener(_onSample);
    widget.binding.addListener(_onSample);
    _painted = widget.binding.sample;
  }

  @override
  void dispose() {
    widget.binding.removeListener(_onSample);
    super.dispose();
  }

  /// Rebuilds only when the sampled geometry actually moved.
  ///
  /// A scroll position notifies for every pixel it travels, and a pinned
  /// section holds one paint offset across its whole window. Rebuilding on an
  /// unchanged sample would repaint the subtree for nothing.
  void _onSample(MotionPathViewportSample sample) {
    if (!mounted || sample == _painted) return;
    _painted = sample;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final MotionPathViewportSample sample = widget.binding.sample;
    _painted = sample;
    if (!sample.visible) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      top: sample.paintOffset,
      child: Align(alignment: widget.alignment, child: widget.child),
    );
  }
}
