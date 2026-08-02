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

MotionPathSpawnController _controller({bool drainOnComplete = false}) =>
    MotionPathSpawnController(
      parent: MotionPathTrackRuntime('carousel-parent'),
      childDuration: 10,
      drainOnComplete: drainOnComplete,
    );

void main() {
  test('reverse scroll rewinds child playheads without changing identity or offsets', () {
    final MotionPathSpawnController controller = _controller();
    controller.spawn(_child('card-a'), stagger: 10);
    controller.spawn(_child('card-b'), stagger: 10);

    controller.advanceTo(15);
    expect(controller.instances.map((MotionPathSpawnInstance i) => i.id), <String>['card-a', 'card-b']);
    expect(controller.instances.map((MotionPathSpawnInstance i) => i.offset), <double>[0, 10]);
    expect(controller.instances.map((MotionPathSpawnInstance i) => i.progress), <double>[1, 0.5]);

    controller.advanceTo(5);
    expect(controller.instances.map((MotionPathSpawnInstance i) => i.id), <String>['card-a', 'card-b']);
    expect(controller.instances.map((MotionPathSpawnInstance i) => i.offset), <double>[0, 10]);
    expect(controller.instances.map((MotionPathSpawnInstance i) => i.progress), <double>[0.5, 0]);
    expect(controller.instances[1].hasStarted, isFalse);

    controller.advanceTo(15);
    expect(controller.instances.map((MotionPathSpawnInstance i) => i.id), <String>['card-a', 'card-b']);
    expect(controller.instances.map((MotionPathSpawnInstance i) => i.progress), <double>[1, 0.5]);
    controller.dispose();
  });

  test('an emptied carousel recovers when a card is added after drain', () {
    final MotionPathSpawnController controller = _controller(drainOnComplete: true);
    controller.spawn(_child('card-a'));
    controller.advanceTo(10);
    expect(controller.instances, isEmpty);

    // A new wave must explicitly restart the playhead after the previous wave
    // drained. Otherwise the controller correctly treats the new child as
    // already complete at the retained elapsed time.
    controller.restartEmptyWave();
    controller.spawn(_child('card-b'));
    expect(controller.instances.map((MotionPathSpawnInstance i) => i.id), <String>['card-b']);
    // Offset zero at elapsed zero means the card is mounted at its first stop,
    // so the controller marks it started immediately. This is distinct from
    // being complete, and it lets the new wave advance normally.
    expect(controller.instances.single.hasStarted, isTrue);
    expect(controller.instances.single.progress, 0);
    controller.advanceTo(5);
    expect(controller.instances.single.progress, closeTo(0.5, 1e-9));
    controller.dispose();
  });
}
