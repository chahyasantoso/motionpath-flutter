import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Observes viewport geometry through a host sampler and an existing scroll
/// position. It never owns a ticker or mutates layout.
class MotionPathViewportPinBinding {
  MotionPathViewportPinBinding({
    this.motion,
    this.delegate,
    this.sampler,
    this.contentOffset,
    this.contentExtent,
    this.viewportExtent,
    this.start = 0,
    this.end = 1,
    this.pinStart = 0,
    this.pinEnd,
    this.onSample,
    this.scrub = 0,
  });

  final MotionPathMotionRuntime? motion;
  final MotionPathViewportPinDelegate? delegate;
  final MotionPathViewportSample Function()? sampler;
  final double? contentOffset;
  final double? contentExtent;
  final double? viewportExtent;
  final double start;
  final double end;
  final double pinStart;
  final double? pinEnd;
  final void Function(MotionPathViewportSample)? onSample;
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

  MotionPathViewportSample sample({double? pixels, double deltaSeconds = 0}) {
    if (_disposed) {
      return _geometrySample(pixels ?? 0);
    }
    final MotionPathViewportSample current = sampler != null
        ? sampler!()
        : _geometrySample(pixels ?? _position?.pixels ?? 0);
    final MotionPathViewportPinDelegate policy =
        delegate ?? const MotionPathViewportPinDelegate();
    final double target = sampler != null || motion != null
        ? policy.progressFor(current)
        : ((current.viewportTop - start) / (end - start))
            .clamp(0.0, 1.0)
            .toDouble();
    final bool pinned = sampler != null || motion != null
        ? policy.isPinned(current)
        : _isGeometryPinned(current);
    _pinned = pinned;
    if (scrub <= 0 || deltaSeconds <= 0) {
      _progress = target;
    } else {
      _progress = MotionPathScrollBinding(start: 0, end: 1, scrub: scrub)
          .scrubToward(_progress, target, deltaSeconds);
    }
    final MotionPathViewportSample result = MotionPathViewportSample(
      targetOffset: current.targetOffset,
      targetExtent: current.targetExtent,
      viewportExtent: current.viewportExtent,
      progress: _progress,
      isPinned: _pinned,
    );
    onSample?.call(result);
    motion?.seek(_progress);
    return result;
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

  MotionPathViewportSample _geometrySample(double pixels) {
    final double top = (contentOffset ?? 0) - pixels;
    return MotionPathViewportSample(
      targetOffset: top,
      targetExtent: contentExtent ?? 0,
      viewportExtent: viewportExtent ?? 0,
    );
  }

  bool _isGeometryPinned(MotionPathViewportSample sample) {
    final double high = pinEnd ?? sample.viewportExtent;
    return sample.viewportBottom >= pinStart && sample.viewportTop <= high;
  }

  void _onScroll() => sample();
}
