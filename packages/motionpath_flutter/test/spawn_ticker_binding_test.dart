import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

class _FakeTickerDriver extends MotionPathTickerDriver {
  _FakeTickerDriver() : super(_FakeEngine(), _FakeProvider());

  final List<void Function(double)> listeners = <void Function(double)>[];

  @override
  void Function() addTickListener(void Function(double delta) listener) {
    listeners.add(listener);
    return () => listeners.remove(listener);
  }

  void emit(double delta) {
    for (final void Function(double) listener
        in List<void Function(double)>.of(listeners)) {
      listener(delta);
    }
  }
}

class _FakeEngine extends MotionPathEngine {}

class _FakeProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

MotionPathTrackRuntime _child(String id) => MotionPathTrackRuntime(
      id,
      properties: <String, List<MotionPathStop>>{
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 100),
        ],
      },
    );

void main() {
  test('advances the spawn surface from the shared ticker delta', () {
    final _FakeTickerDriver driver = _FakeTickerDriver();
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
      childDuration: 10,
    );
    controller.spawn(_child('child'));
    final MotionPathSpawnTickerBinding binding =
        MotionPathSpawnTickerBinding(driver: driver, controller: controller);

    driver.emit(5);

    expect(controller.instances.single.progress, closeTo(0.5, 1e-9));
    expect(binding.isAttached, isTrue);

    binding.dispose();
    expect(binding.isAttached, isFalse);
    controller.dispose();
    driver.dispose();
  });

  test('disposing the binding leaves the shared driver alone', () {
    final _FakeTickerDriver driver = _FakeTickerDriver();
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
    );
    final MotionPathSpawnTickerBinding binding =
        MotionPathSpawnTickerBinding(driver: driver, controller: controller);

    binding.dispose();
    binding.dispose();
    driver.emit(1);

    expect(driver.listeners, isEmpty);
    expect(binding.isAttached, isFalse);
    expect(driver.isActive, isFalse);
    controller.dispose();
    driver.dispose();
  });
}
