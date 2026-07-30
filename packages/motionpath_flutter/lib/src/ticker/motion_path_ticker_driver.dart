import 'package:flutter/scheduler.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// The single frame source for one engine.
class MotionPathTickerDriver {
  MotionPathTickerDriver(this.engine, TickerProvider provider) {
    _ticker = provider.createTicker(_tick);
  }

  final MotionPathEngine engine;
  late final Ticker _ticker;
  Duration? _last;
  bool _disposed = false;

  bool get isActive => !_disposed && _ticker.isActive;

  void start() {
    if (!_disposed && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void stop() {
    if (_disposed) return;
    _ticker.stop();
    _last = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ticker.dispose();
    _last = null;
  }

  void _tick(Duration elapsed) {
    if (_disposed) return;
    final Duration? previous = _last;
    _last = elapsed;
    if (previous == null) return;
    final double delta =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    if (delta > 0) engine.tick(delta);
  }
}
