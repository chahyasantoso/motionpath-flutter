import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Observes viewport geometry through a host sampler and an existing scroll
/// position. It never owns a ticker or mutates layout.
class MotionPathViewportPinBinding {
  MotionPathViewportPinBinding({required this.motion, required this.delegate, required this.sampler, this.scrub = 0});
  final MotionPathMotionRuntime motion;
  final MotionPathViewportPinDelegate delegate;
  final MotionPathViewportSample Function() sampler;
  final double scrub;
  ScrollPosition? _position;
  double _progress = 0;
  bool _pinned = false;
  bool _disposed = false;

  bool get isAttached => _position != null;
  double get progress => _progress;
  bool get isPinned => _pinned;

  void attach(ScrollPosition position) {
    if (_disposed) return;
    detach();
    _position = position;
    position.addListener(_onScroll);
    sample();
  }

  void sample({double deltaSeconds = 0}) {
    if (_disposed) return;
    final current = sampler();
    final target = delegate.progressFor(current);
    _pinned = delegate.isPinned(current);
    if (scrub <= 0 || deltaSeconds <= 0) {
      _progress = target;
    } else {
      _progress = MotionPathScrollBinding(start: 0, end: 1, scrub: scrub).scrubToward(_progress, target, deltaSeconds);
    }
    motion.seek(_progress);
  }

  void detach() {
    _position?.removeListener(_onScroll);
    _position = null;
    _progress = 0;
    _pinned = false;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    detach();
  }

  void _onScroll() => sample();
}
