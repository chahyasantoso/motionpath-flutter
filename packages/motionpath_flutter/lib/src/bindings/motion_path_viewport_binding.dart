import 'package:flutter/widgets.dart';

/// A sampled viewport state for a scroll-driven scene.
class MotionPathViewportSample {
  const MotionPathViewportSample({
    required this.progress,
    required this.isPinned,
    required this.viewportTop,
    required this.viewportBottom,
  });

  final double progress;
  final bool isPinned;
  final double viewportTop;
  final double viewportBottom;
}

/// Observes one content region and reports scroll progress plus pin state.
///
/// This binding owns no ticker and performs no layout mutation. The host gets a
/// pure sample and decides how to render or position the pinned child.
class MotionPathViewportPinBinding {
  MotionPathViewportPinBinding({
    required this.contentOffset,
    required this.contentExtent,
    required this.viewportExtent,
    required this.onSample,
    this.start = 0,
    this.end,
    this.pinStart = 0,
    this.pinEnd,
  });

  final double contentOffset;
  final double contentExtent;
  final double viewportExtent;
  final void Function(MotionPathViewportSample sample) onSample;
  final double start;
  final double? end;
  final double pinStart;
  final double? pinEnd;

  ScrollPosition? _position;
  bool _disposed = false;

  bool get isAttached => _position != null && !_disposed;

  void attach(ScrollPosition position) {
    if (_disposed) return;
    detach();
    _position = position;
    position.addListener(_sampleCurrent);
    _sampleCurrent();
  }

  void detach() {
    _position?.removeListener(_sampleCurrent);
    _position = null;
  }

  MotionPathViewportSample sample({required double pixels}) {
    final double top = contentOffset - pixels;
    final double bottom = top + contentExtent;
    final double pinLimit = pinEnd ?? viewportExtent - contentExtent;
    final double window = (end ?? viewportExtent) - start;
    final double progress = window <= 0
        ? (top <= start ? 1 : 0)
        : ((top - start) / window).clamp(0.0, 1.0).toDouble();
    final bool pinned = top <= pinStart && bottom >= pinLimit;
    return MotionPathViewportSample(
      progress: progress,
      isPinned: pinned,
      viewportTop: top,
      viewportBottom: bottom,
    );
  }

  void _sampleCurrent() {
    final ScrollPosition? position = _position;
    if (position == null || _disposed) return;
    onSample(sample(pixels: position.pixels));
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    detach();
  }
}
