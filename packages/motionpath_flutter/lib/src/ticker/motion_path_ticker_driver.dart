import 'package:flutter/scheduler.dart';
import 'package:motionpath_core/motionpath_core.dart';

class MotionPathTickerDriver {
  MotionPathTickerDriver(this.engine, TickerProvider provider) {
    _ticker = provider.createTicker(_tick);
  }

  final MotionPathEngine engine;
  late final Ticker _ticker;
  Duration? _last;

  void start() => _ticker.start();
  void stop() => _ticker.stop();

  void dispose() => _ticker.dispose();

  void _tick(Duration elapsed) {
    final previous = _last;
    _last = elapsed;
    if (previous == null) return;
    // Engine tick integration follows in the next runtime slice. This driver
    // deliberately owns the only frame source and currently measures delta.
    final delta = (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    if (delta < 0) _last = elapsed;
  }
}
