import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Samples viewport geometry and seeks a motion without owning a clock.
///
/// The [sampler] is the widget-layer observation boundary: it can read a
/// RenderBox, a sliver, or a test fixture and return viewport coordinates. This
/// binding only subscribes to an existing [ScrollPosition]. It never creates a
/// ticker and never mutates layout, so pinning remains composable with the
/// normal Flutter viewport.
class MotionPathViewportPinBinding {
  /// Creates a viewport pin binding.
  MotionPathViewportPinBinding({
    required this.motion,
    required this.delegate,
    required this.sampler,
  });

  /// Motion driven by viewport position.
  final MotionPathMotionRuntime motion;

  /// Geometry policy that maps samples to progress and pin state.
  final MotionPathViewportPinDelegate delegate;

  /// Reads the current target geometry in viewport coordinates.
  final MotionPathViewportSample Function() sampler;

  ScrollPosition? _position;
  double _progress = 0;
  bool _pinned = false;
  bool _disposed = false;

  /// Whether a scroll position is attached.
  bool get isAttached => _position != null;

  /// Last applied progress.
  double get progress => _progress;

  /// Whether the last sample is inside the pin window.
  bool get isPinned => _pinned;

  /// Attaches to [position] and samples immediately.
  void attach(ScrollPosition position) {
    if (_disposed) return;
    detach();
    _position = position;
    position.addListener(_onScroll);
    sample();
  }

  /// Samples geometry and applies progress immediately.
  ///
  /// Pass [deltaSeconds] only when the caller has an existing clock and wants
  /// scrub smoothing; the binding never measures or creates time itself.
  void sample({double deltaSeconds = 0}) {
    if (_disposed) return;
    final MotionPathViewportSample current = sampler();
    final double target = delegate.progressFor(current);
    _pinned = delegate.isPinned(current);
    if (deltaSeconds <= 0) {
      _progress = target;
    } else {
      final MotionPathScrollBinding scrub = MotionPathScrollBinding(
        start: 0,
        end: 1,
        scrub: deltaSeconds,
      );
      _progress = scrub.scrubToward(_progress, target, deltaSeconds);
    }
    motion.seek(_progress);
  }

  /// Detaches from the position and resets sampled state.
  void detach() {
    _position?.removeListener(_onScroll);
    _position = null;
    _progress = 0;
    _pinned = false;
  }

  /// Releases the scroll subscription. Idempotent.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    detach();
  }

  void _onScroll() => sample();
}
