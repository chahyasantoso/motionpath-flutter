import 'package:flutter/widgets.dart';

import '../bindings/motion_path_viewport_binding.dart';

/// Positions arbitrary viewport content from [MotionPathViewportSample].
///
/// Unlike [MotionPathPinnedHeader], this host works inside a Stack and can pin
/// at the viewport's leading edge for any authored scroll window. The binding
/// owns sampling; this widget only listens and lays out the supplied child.
class MotionPathArbitraryPinned extends StatefulWidget {
  const MotionPathArbitraryPinned({required this.binding, required this.child, this.alignment = Alignment.topLeft, super.key});
  final MotionPathViewportBinding binding;
  final Widget child;
  final Alignment alignment;
  @override
  State<MotionPathArbitraryPinned> createState() => _MotionPathArbitraryPinnedState();
}

class _MotionPathArbitraryPinnedState extends State<MotionPathArbitraryPinned> {
  @override
  void initState() { super.initState(); widget.binding.addListener(_onSample); }
  @override
  void didUpdateWidget(covariant MotionPathArbitraryPinned oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.binding != widget.binding) { oldWidget.binding.removeListener(_onSample); widget.binding.addListener(_onSample); } }
  @override
  void dispose() { widget.binding.removeListener(_onSample); super.dispose(); }
  void _onSample(MotionPathViewportSample sample) { if (mounted) setState(() {}); }
  @override
  Widget build(BuildContext context) {
    final MotionPathViewportSample sample = widget.binding.sample;
    if (!sample.visible) return const SizedBox.shrink();
    return Positioned.fill(
      top: sample.paintOffset,
      bottom: null,
      child: Align(alignment: widget.alignment, child: widget.child),
    );
  }
}
