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

MotionPathSpawnController _controller() => MotionPathSpawnController(
      parent: MotionPathTrackRuntime('carousel-parent'),
      childDuration: 10,
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
}
