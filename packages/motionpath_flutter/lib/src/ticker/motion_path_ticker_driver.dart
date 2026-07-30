import 'package:flutter/scheduler.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// The single frame source for one engine.
///
/// There is exactly one active frame source per engine integration. This driver
/// may use a [Ticker], but nothing else may add a timer or animation loop for
/// the same engine.
class MotionPathTickerDriver {
  /// Creates a driver bound to [provider].
  MotionPathTickerDriver(this.engine, TickerProvider provider) {
    _ticker = provider.createTicker(_tick);
  }

  /// Engine advanced by this driver.
  final MotionPathEngine engine;

  late final Ticker _ticker;
  Duration? _last;

  /// Whether the ticker is currently running.
  bool get isActive => _ticker.isActive;

  /// Starts the frame source.
  void start() => _ticker.start();

  /// Stops the frame source without disposing it.
  void stop() {
    _ticker.stop();
    _last = null;
  }

  /// Releases the ticker.
  void dispose() => _ticker.dispose();

  void _tick(Duration elapsed) {
    final Duration? previous = _last;
    _last = elapsed;
    if (previous == null) {
      return;
    }
    final double delta =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    if (delta > 0) {
      engine.tick(delta);
    }
  }
}
