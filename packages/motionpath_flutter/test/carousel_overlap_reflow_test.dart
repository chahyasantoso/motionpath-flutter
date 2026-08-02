import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _card(String id) => MotionPathTrackRuntime(
      id,
      properties: <String, List<MotionPathStop>>{
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 50),
          MotionPathStop(progress: 1, value: 50),
        ],
        'y': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 50),
          MotionPathStop(progress: 1, value: 50),
        ],
      },
    );

void main() {
  test('overlapping cards hit the front-most instance first', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('carousel-parent'),
    );
    controller.spawn(_card('back'));
    controller.spawn(_card('front'), stagger: 10);

    final List<String> tested = <String>[];
    final MotionPathSpawnInstance? hit = motionPathHitTest(
      controller.instances,
      (MotionPathSpawnInstance instance) {
        tested.add(instance.id);
        final Map<String, Object?> patch = instance.patch;
        final double x = (patch['x']! as num).toDouble();
        final double y = (patch['y']! as num).toDouble();
        return x == 50 && y == 50;
      },
    );

    expect(hit?.id, 'front');
    expect(tested, <String>['front']);
    controller.dispose();
  });

  test('middle removal reflows survivors without teleporting the next card', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('carousel-parent'),
      childDuration: 100,
      reflowDuration: 2,
    );
    controller.spawn(_card('a'), stagger: 10);
    controller.spawn(_card('b'), stagger: 10);
    controller.spawn(_card('c'), stagger: 10);
    controller.advanceTo(5);

    controller.remove('b');

    expect(controller.instances.map((MotionPathSpawnInstance i) => i.id), <String>['a', 'c']);
    expect(controller.instances.last.offset, 20);
    controller.advanceBy(1);
    expect(controller.instances.last.id, 'c');
    expect(controller.instances.last.offset, closeTo(15, 1e-9));
    controller.advanceBy(1);
    expect(controller.instances.last.offset, 10);
    controller.dispose();
  });
}
