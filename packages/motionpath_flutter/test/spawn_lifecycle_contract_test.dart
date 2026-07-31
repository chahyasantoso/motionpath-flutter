import 'package:flutter/scheduler.dart' show Ticker, TickerCallback, TickerProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

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
  test('restartEmptyWave resets time only after the parent drains', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
      childDuration: 1,
      drainOnComplete: true,
    );
    controller.spawn(_child('a'));
    controller.advanceTo(1);
    expect(controller.liveCount, 0);

    controller.restartEmptyWave();
    controller.spawn(_child('b'));
    expect(controller.elapsed, 0);
    expect(controller.instances.single.hasStarted, isTrue);
    controller.dispose();
  });

  test('restartEmptyWave does not rewind a live wave', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
      childDuration: 10,
    );
    controller.spawn(_child('a'));
    controller.advanceTo(5);
    controller.restartEmptyWave();
    expect(controller.elapsed, 5);
    expect(controller.instances.single.progress, closeTo(0.5, 1e-9));
    controller.dispose();
  });

  test('shared ticker binding detaches without stopping the driver', () {
    final MotionPathEngine engine = MotionPathEngine();
    final MotionPathTickerDriver driver = MotionPathTickerDriver(
      engine,
      const TestVSync(),
    );
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
    );
    final MotionPathSpawnTickerBinding binding = MotionPathSpawnTickerBinding(
      driver: driver,
      controller: controller,
    );
    expect(binding.isAttached, isTrue);
    binding.dispose();
    binding.dispose();
    expect(binding.isAttached, isFalse);
    controller.dispose();
    driver.dispose();
    engine.destroy();
  });
}

class TestVSync implements TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
