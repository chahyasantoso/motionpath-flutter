import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('addTickListener returns a disposer that is safe to call repeatedly', () {
    final MotionPathTickerDriver driver = _FakeTickerDriver();
    final List<double> received = <double>[];
    final void Function() remove = driver.addTickListener(received.add);

    remove();
    remove();

    expect(received, isEmpty);
    driver.dispose();
  });
}

class _FakeTickerDriver extends MotionPathTickerDriver {
  _FakeTickerDriver() : super(_engine, _provider);

  static final MotionPathEngine _engine = MotionPathEngine();
  static final _FakeTickerProvider _provider = _FakeTickerProvider();
}

class _FakeTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
