import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

class MotionPathViewportSample {
  const MotionPathViewportSample({required this.scrollPixels, required this.localOffset, required this.progress, required this.visible, required this.pinned, required this.paintOffset});
  final double scrollPixels;
  final double localOffset;
  final double progress;
  final bool visible;
  final bool pinned;
  final double paintOffset;
}

typedef MotionPathViewportListener = void Function(MotionPathViewportSample sample);

class MotionPathViewportBinding {
  MotionPathViewportBinding({required this.motion, required this.itemStart, required this.itemExtent, required this.viewportExtent, this.start = 0, this.end = 1, this.pin = false, this.onSample, this.onToggle}) { MotionPathToggleStateMachine.validateWindow(start, end); }
  final MotionPathMotionRuntime motion;
  final double itemStart;
  final double itemExtent;
  final double viewportExtent;
  final double start;
  final double end;
  final bool pin;
  final void Function(MotionPathViewportSample sample)? onSample;
  final void Function(MotionPathToggleAction action)? onToggle;
  final MotionPathToggleStateMachine _toggles = MotionPathToggleStateMachine();
  final List<MotionPathViewportListener> _listeners = <MotionPathViewportListener>[];
  ScrollPosition? _position;
  bool _disposed = false;
  MotionPathViewportSample _sample = _zeroSample;
  static const MotionPathViewportSample _zeroSample = MotionPathViewportSample(scrollPixels: 0, localOffset: 0, progress: 0, visible: false, pinned: false, paintOffset: 0);
  bool get isAttached => _position != null;
  bool get isDisposed => _disposed;
  MotionPathViewportSample get sample => _sample;
  MotionPathTriggerZone? get zone => _toggles.zone;

  void addListener(MotionPathViewportListener listener) { if (!_listeners.contains(listener)) _listeners.add(listener); }
  void removeListener(MotionPathViewportListener listener) { _listeners.remove(listener); }

  static MotionPathViewportSample sampleAt({required double scrollPixels, required double itemStart, required double itemExtent, required double viewportExtent, double start = 0, double end = 1, bool pin = false}) {
    MotionPathToggleStateMachine.validateWindow(start, end);
    final double span = end - start;
    final double progress = span <= 0 ? (scrollPixels >= end ? 1 : 0) : ((scrollPixels - start) / span).clamp(0.0, 1.0).toDouble();
    final double localOffset = itemStart - scrollPixels;
    final bool visible = localOffset < viewportExtent && localOffset + itemExtent > 0 && itemExtent > 0 && viewportExtent > 0;
    final bool pinned = pin && progress > 0 && progress < 1;
    final double paintOffset = pinned ? 0 : localOffset.clamp(-itemExtent, viewportExtent).toDouble();
    return MotionPathViewportSample(scrollPixels: scrollPixels, localOffset: localOffset, progress: progress, visible: visible, pinned: pinned, paintOffset: paintOffset);
  }

  void attach(ScrollPosition position) { if (_disposed) return; detach(); _position = position; position.addListener(_onScroll); _onScroll(); }
  void detach() { _position?.removeListener(_onScroll); _position = null; _sample = _zeroSample; _toggles.reset(); }
  void sampleFromOffset(double scrollPixels) {
    if (_disposed) return;
    _sample = sampleAt(scrollPixels: scrollPixels, itemStart: itemStart, itemExtent: itemExtent, viewportExtent: viewportExtent, start: start, end: end, pin: pin);
    motion.seek(_sample.progress);
    final List<MotionPathToggleAction> actions = _toggles.updateForValue(value: scrollPixels, start: start, end: end);
    final void Function(MotionPathToggleAction action)? toggle = onToggle;
    if (toggle != null) for (final MotionPathToggleAction action in actions) { toggle(action); }
    onSample?.call(_sample);
    for (final MotionPathViewportListener listener in List<MotionPathViewportListener>.of(_listeners)) { listener(_sample); }
  }
  void _onScroll() { if (_disposed) return; final ScrollPosition? position = _position; if (position != null) sampleFromOffset(position.pixels); }
  void dispose() { if (_disposed) return; _disposed = true; detach(); _listeners.clear(); }
}
