import 'package:meta/meta.dart';

/// A layout sample supplied by a viewport adapter.
///
/// [targetOffset] is the target's leading edge in viewport coordinates. The
/// core does not inspect RenderObjects or scroll positions; adapters provide
/// this small observation record.
@immutable
class MotionPathViewportSample {
  /// Creates a viewport sample.
  const MotionPathViewportSample({
    required this.targetOffset,
    required this.targetExtent,
    required this.viewportExtent,
  });

  /// Target leading edge, in logical pixels relative to the viewport.
  final double targetOffset;

  /// Target extent, in logical pixels.
  final double targetExtent;

  /// Viewport extent, in logical pixels.
  final double viewportExtent;
}

/// Maps a target's viewport position onto motion progress.
///
/// [enterAt] and [exitAt] are viewport fractions. Progress is zero when the
/// target leading edge reaches [enterAt], and one when it reaches [exitAt].
/// The target is considered pinned while its leading edge is inside that
/// interval. This is geometry only: no scroll listener, ticker, or layout
/// mutation lives in the pure Dart core.
class MotionPathViewportPinDelegate {
  /// Creates a viewport pinning policy.
  const MotionPathViewportPinDelegate({
    this.enterAt = 1,
    this.exitAt = 0,
  });

  /// Viewport fraction where the target enters the pin window.
  final double enterAt;

  /// Viewport fraction where the target exits the pin window.
  final double exitAt;

  /// Computes normalized progress for [sample].
  double progressFor(MotionPathViewportSample sample) {
    final double span = sample.viewportExtent * (exitAt - enterAt);
    if (sample.viewportExtent <= 0 || span == 0) {
      return sample.targetOffset <= sample.viewportExtent * enterAt ? 1 : 0;
    }
    return ((sample.targetOffset - sample.viewportExtent * enterAt) / span)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  /// Whether [sample] is currently inside the pin window.
  bool isPinned(MotionPathViewportSample sample) {
    final double low = sample.viewportExtent *
        (enterAt < exitAt ? enterAt : exitAt);
    final double high = sample.viewportExtent *
        (enterAt > exitAt ? enterAt : exitAt);
    return sample.targetOffset >= low && sample.targetOffset <= high;
  }
}
