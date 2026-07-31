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
  test('reflow uses the authored duration instead of jumping immediately', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
      childDuration: 100,
      reflowDuration: 2,
      reflowEase: MotionPathInterpolators.linear,
    );
    controller.spawn(_child('a'), stagger: 10);
    controller.spawn(_child('b'), stagger: 10);
    controller.spawn(_child('c'), stagger: 10);
    controller.advanceTo(5);

    controller.remove('b');

    expect(controller.instances[1].id, 'c');
    expect(controller.instances[1].offset, 20);
    controller.advanceBy(1);
    expect(controller.instances[1].offset, closeTo(15, 1e-9));
    expect(controller.instances[1].progress, closeTo((5 - 15) / 100, 1e-9));
    controller.advanceBy(1);
    expect(controller.instances[1].offset, 10);
    controller.dispose();
  });

  test('zero reflow duration preserves immediate settled behavior', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
      childDuration: 10,
    );
    controller.spawn(_child('a'), stagger: 10);
    controller.spawn(_child('b'), stagger: 10);
    controller.spawn(_child('c'), stagger: 10);
    controller.remove('b');

    expect(controller.instances[1].offset, 10);
    controller.dispose();
  });

  test('reflow retargets from the current animated offset', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
      childDuration: 100,
      reflowDuration: 2,
    );
    controller.spawn(_child('a'), stagger: 10);
    controller.spawn(_child('b'), stagger: 10);
    controller.spawn(_child('c'), stagger: 10);
    controller.advanceTo(1);
    controller.remove('b');
    controller.advanceBy(1);
    controller.remove('a');

    expect(controller.instances.single.id, 'c');
    expect(controller.instances.single.offset, closeTo(12.5, 1e-9));
    controller.dispose();
  });
}
