import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _child(String id) => MotionPathTrackRuntime(id);

void main() {
  test('keeps controller snapshots ascending and exposes top-most order separately', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
    );
    controller.spawn(_child('first'));
    controller.spawn(_child('second'), stagger: 5);
    controller.spawn(_child('third'), stagger: 5);

    expect(controller.instances.map((MotionPathSpawnInstance i) => i.id),
        <String>['first', 'second', 'third']);
    expect(
      motionPathTopMostFirst(controller.instances)
          .map((MotionPathSpawnInstance i) => i.id),
      <String>['third', 'second', 'first'],
    );
    controller.dispose();
  });
}
