import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Maps a Flutter scroll position onto a motion playhead.
///
/// Scroll-driven motions are sampled through scroll notifications and mapped to
/// `seek`. This binding never starts a ticker, so a scrubbed motion and a
/// time-driven motion can share one engine without competing frame sources.
class MotionPathMotionScrollBinding {
  /// Creates a binding for [motion].
  ///
  /// [start] and [end] are scroll offsets in logical pixels. When [end] is null
  /// the scrollable's own `maxScrollExtent` is used. [scrub] is the smoothing
  /// window in seconds. Smoothing only occurs when the caller supplies a
  /// positive [deltaSeconds] to [seekFromOffset], keeping clock ownership
  /// outside this adapter.
  MotionPathMotionScrollBinding({
    required this.motion,
    this.start = 0,
    this.end,
    this.scrub = 0,
  });

  /// Motion driven by scroll position.
  final MotionPathMotionRuntime motion;

  /// Scroll offset mapped to progress `0`.
  final double start;

  /// Scroll offset mapped to progress `1`.
  final double? end;

  /// Smoothing window in seconds. Zero applies samples immediately.
  final double scrub;

  ScrollPosition? _position;
  double _progress = 0;
  double _targetProgress = 0;

  /// Whether a scroll position is currently attached.
  bool get isAttached => _position != null;

  /// Most recently applied progress.
  double get progress => _progress;

  /// Most recently sampled target progress before scrub smoothing.
  double get targetProgress => _targetProgress;

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

  /// Detaches from the current scroll position. Idempotent and state-resetting.
  void detach() {
    _position?.removeListener(_onScroll);
    _position = null;
    _progress = 0;
    _targetProgress = 0;
  }

  /// Seeks the motion from an already sampled scroll offset.
  ///
  /// The caller owns the clock. Pass the elapsed time since the previous
  /// sample to apply authored scrub smoothing; omit it to snap immediately.
  void seekFromOffset({
    required double pixels,
    required double maxScrollExtent,
    double deltaSeconds = 0,
  }) {
    _targetProgress = progressForOffset(
      pixels: pixels,
      maxScrollExtent: maxScrollExtent,
      start: start,
      end: end,
    );
    final MotionPathScrollBinding math = MotionPathScrollBinding(
      start: 0,
      end: 1,
      scrub: scrub,
    );
    _progress = math.scrubToward(_progress, _targetProgress, deltaSeconds);
    motion.seek(_progress);
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

  /// Releases the scroll subscription and resets sampled state.
  void dispose() => detach();
}
