import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Renderer-neutral viewport state for a positioned scene element.
class MotionPathViewportSample {
  const MotionPathViewportSample({
    required this.scrollPixels,
    required this.localOffset,
    required this.progress,
    required this.visible,
    required this.pinned,
    required this.paintOffset,
  });

  final double scrollPixels;
  final double localOffset;
  final double progress;
  final bool visible;
  final bool pinned;
  final double paintOffset;
}

/// Samples an element against a scroll viewport without owning a clock.
///
/// [itemStart] and [itemExtent] are content-space geometry supplied by the
/// host. [start] and [end] define the scroll window that drives the motion.
/// While inside that window, [pin] keeps the element at the viewport's leading
/// edge and reports the pinned state so a host can render it accordingly. This
/// class does not mutate scroll position and never creates a ticker.
class MotionPathViewportBinding {
  MotionPathViewportBinding({
    required this.motion,
    required this.itemStart,
    required this.itemExtent,
    required this.viewportExtent,
    this.start = 0,
    this.end = 1,
    this.pin = false,
    this.onSample,
  });

  final MotionPathMotionRuntime motion;
  final double itemStart;
  final double itemExtent;
  final double viewportExtent;
  final double start;
  final double end;
  final bool pin;
  final void Function(MotionPathViewportSample sample)? onSample;

  ScrollPosition? _position;
  MotionPathViewportSample _sample = const MotionPathViewportSample(
    scrollPixels: 0,
    localOffset: 0,
    progress: 0,
    visible: false,
    pinned: false,
    paintOffset: 0,
  );

  bool get isAttached => _position != null;
  MotionPathViewportSample get sample => _sample;

  static MotionPathViewportSample sampleAt({
    required double scrollPixels,
    required double itemStart,
    required double itemExtent,
    required double viewportExtent,
    double start = 0,
    double end = 1,
    bool pin = false,
  }) {
    final double span = end - start;
    final double progress = span <= 0
        ? (scrollPixels >= end ? 1 : 0)
        : ((scrollPixels - start) / span).clamp(0.0, 1.0).toDouble();
    final double localOffset = itemStart - scrollPixels;
    final bool visible = localOffset < viewportExtent &&
        localOffset + itemExtent > 0 &&
        itemExtent > 0 &&
        viewportExtent > 0;
    final bool pinned = pin && progress > 0 && progress < 1;
    final double paintOffset = pinned
        ? 0
        : localOffset.clamp(-itemExtent, viewportExtent).toDouble();
    return MotionPathViewportSample(
      scrollPixels: scrollPixels,
      localOffset: localOffset,
      progress: progress,
      visible: visible,
      pinned: pinned,
      paintOffset: paintOffset,
    );
  }

  /// Attaches to [position] and samples immediately.
  void attach(ScrollPosition position) {
    detach();
    _position = position;
    position.addListener(_onScroll);
    _onScroll();
  }

  /// Detaches and resets the last sample for safe route/viewport reuse.
  void detach() {
    _position?.removeListener(_onScroll);
    _position = null;
    _sample = const MotionPathViewportSample(
      scrollPixels: 0,
      localOffset: 0,
      progress: 0,
      visible: false,
      pinned: false,
      paintOffset: 0,
    );
  }

  /// Samples an already-known scroll offset. The caller owns scheduling.
  void sampleFromOffset(double scrollPixels) {
    _sample = sampleAt(
      scrollPixels: scrollPixels,
      itemStart: itemStart,
      itemExtent: itemExtent,
      viewportExtent: viewportExtent,
      start: start,
      end: end,
      pin: pin,
    );
    motion.seek(_sample.progress);
    onSample?.call(_sample);
  }

  void _onScroll() {
    final ScrollPosition? position = _position;
    if (position != null) {
      sampleFromOffset(position.pixels);
    }
  }

  void dispose() => detach();
}
