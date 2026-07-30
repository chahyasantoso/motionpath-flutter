import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Maps a Flutter scroll position onto a motion playhead.
///
/// Scroll-driven motions are sampled through scroll notifications and mapped to
/// `seek`. This binding never starts a ticker, so a scrubbed motion and a
/// time-driven motion can share one engine without competing frame sources.
///
/// Named for the motion it drives rather than for scrolling, because the core
/// already owns a renderer-neutral `MotionPathScrollBinding` that holds the
/// offset-window and scrub math. This is the Flutter plumbing on top of it.
class MotionPathMotionScrollBinding {
  /// Creates a binding for [motion].
  ///
  /// [start] and [end] are scroll offsets in logical pixels. When [end] is null
  /// the scrollable's own `maxScrollExtent` is used.
  MotionPathMotionScrollBinding({
    required this.motion,
    this.start = 0,
    this.end,
  });

  /// Motion driven by scroll position.
  final MotionPathMotionRuntime motion;

  /// Scroll offset mapped to progress `0`.
  final double start;

  /// Scroll offset mapped to progress `1`.
  final double? end;

  ScrollPosition? _position;

  /// Whether a scroll position is currently attached.
  bool get isAttached => _position != null;

  /// Maps a raw scroll offset onto normalized progress.
  static double progressForOffset({
    required double pixels,
    required double maxScrollExtent,
    double start = 0,
    double? end,
  }) {
    final double to = end ?? maxScrollExtent;
    final double span = to - start;
    if (span <= 0) {
      return pixels <= start ? 0 : 1;
    }
    return ((pixels - start) / span).clamp(0.0, 1.0).toDouble();
  }

  /// Attaches to [position] and seeks once so the first frame is correct.
  void attach(ScrollPosition position) {
    detach();
    _position = position;
    position.addListener(_onScroll);
    _onScroll();
  }

  /// Detaches from the current scroll position. Idempotent.
  void detach() {
    _position?.removeListener(_onScroll);
    _position = null;
  }

  /// Seeks the motion from an already sampled scroll offset.
  void seekFromOffset({
    required double pixels,
    required double maxScrollExtent,
  }) {
    motion.seek(progressForOffset(
      pixels: pixels,
      maxScrollExtent: maxScrollExtent,
      start: start,
      end: end,
    ));
  }

  void _onScroll() {
    final ScrollPosition? position = _position;
    if (position == null) {
      return;
    }
    seekFromOffset(
      pixels: position.pixels,
      maxScrollExtent: position.maxScrollExtent,
    );
  }

  /// Releases the scroll subscription.
  void dispose() => detach();
}
