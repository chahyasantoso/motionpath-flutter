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
    for (final void Function(double) listener in List<void Function(double)>.of(
      listeners,
    )) {
      listener(delta);
    }
  }
}

class _FakeEngine extends MotionPathEngine {}

class _FakeProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

MotionPathTrackRuntime _card(String id) => MotionPathTrackRuntime(
      id,
      properties: <String, List<MotionPathStop>>{
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 100),
        ],
      },
    );

void main() {
  test('disposing the Carousel scroll binding stops future card updates', () {
    final _FakeTickerDriver driver = _FakeTickerDriver();
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('carousel-parent'),
      childDuration: 10,
    );
    controller.spawn(_card('card'));
    final MotionPathSpawnTickerBinding binding = MotionPathSpawnTickerBinding(
      driver: driver,
      controller: controller,
    );

    driver.emit(5);
    expect(controller.elapsed, 5);
    expect(controller.instances.single.progress, closeTo(0.5, 1e-9));

    binding.dispose();
    binding.dispose();
    driver.emit(5);

    expect(binding.isAttached, isFalse);
    expect(controller.elapsed, 5);
    expect(controller.instances.single.progress, closeTo(0.5, 1e-9));
    expect(driver.listeners, isEmpty);

    controller.dispose();
    driver.dispose();
  });

  test('disposing the Carousel controller releases its parent hooks and blocks updates', () {
    final _FakeTickerDriver driver = _FakeTickerDriver();
    final MotionPathTrackRuntime parent = MotionPathTrackRuntime('carousel-parent');
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: parent,
      childDuration: 10,
    );
    controller.spawn(_card('card'));
    final MotionPathSpawnTickerBinding binding = MotionPathSpawnTickerBinding(
      driver: driver,
      controller: controller,
    );

    controller.dispose();
    driver.emit(5);
    parent.addChild(_card('late'));

    expect(controller.isDisposed, isTrue);
    expect(controller.instances, isEmpty);
    expect(controller.parent.onChildSpawned, isNull);
    expect(controller.parent.onChildRemoved, isNull);
    expect(controller.parent.onChildReflowed, isNull);
    expect(driver.listeners, hasLength(1));

    binding.dispose();
    driver.dispose();
  });
}
