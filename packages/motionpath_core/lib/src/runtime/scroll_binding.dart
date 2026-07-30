import 'dart:math' as math;

/// Maps a scroll offset onto normalized motion progress.
///
/// This is deliberately renderer-neutral: it knows nothing about Flutter's
/// `ScrollPosition`, so the same math serves a widget, a test, or a headless
/// harness. The Flutter package owns the plumbing.
class MotionPathScrollBinding {
  /// Creates a binding over the `[start, end]` offset window.
  ///
  /// [scrub] is the smoothing window in seconds, matching the authored
  /// `trigger.scrub` value in v4 JSON. Zero means snap straight to the offset.
  const MotionPathScrollBinding({this.start = 0, this.end = 1, this.scrub = 0});

  /// Offset where progress reaches zero.
  final double start;

  /// Offset where progress reaches one.
  final double end;

  /// Smoothing window in seconds.
  final double scrub;

  /// Normalizes [offset] into `[0, 1]`.
  double progressFor(double offset) {
    final double span = end - start;
    if (span <= 0) return offset >= end ? 1 : 0;
    final double raw = (offset - start) / span;
    if (raw < 0) return 0;
    if (raw > 1) return 1;
    return raw;
  }

  /// Eases [current] toward [target] across [delta] seconds.
  ///
  /// With no [scrub] the target is applied immediately, which keeps a scrubbed
  /// timeline frame-accurate when smoothing is not authored.
  double scrubToward(double current, double target, double delta) {
    if (scrub <= 0 || delta <= 0) return target;
    final double factor = 1 - math.exp(-delta / scrub);
    final double clamped = factor > 1 ? 1 : factor;
    return current + (target - current) * clamped;
  }
}
