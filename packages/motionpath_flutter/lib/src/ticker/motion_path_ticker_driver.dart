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
  final List<void Function(double)> _tickListeners = <void Function(double)>[];

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

  /// Adds a consumer to the same frame delta used by [engine].
  ///
  /// This is the integration seam for renderer adapters such as a spawn
  /// surface. It does not create another ticker or alter frame ordering.
  void Function() addTickListener(void Function(double delta) listener) {
    if (_disposed) {
      return () {};
    }
    _tickListeners.add(listener);
    return () => _tickListeners.remove(listener);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ticker.dispose();
    _last = null;
    _tickListeners.clear();
  }

  void _tick(Duration elapsed) {
    if (_disposed) return;
    final Duration? previous = _last;
    _last = elapsed;
    if (previous == null) return;
    final double delta =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    if (delta > 0) {
      engine.tick(delta);
      for (final void Function(double) listener
          in List<void Function(double)>.of(_tickListeners)) {
        listener(delta);
      }
    }
  }
}
