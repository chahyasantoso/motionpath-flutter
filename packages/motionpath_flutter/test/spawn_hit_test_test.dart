import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _child(String id) => MotionPathTrackRuntime(id);

void main() {
  test('hit tests front-most instances before lower instances', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
    );
    controller.spawn(_child('back'));
    controller.spawn(_child('front'), stagger: 10);

    final List<String> tested = <String>[];
    final MotionPathSpawnInstance? hit = motionPathHitTest(
      controller.instances,
      (MotionPathSpawnInstance instance) {
        tested.add(instance.id);
        return true;
      },
    );

    expect(hit?.id, 'front');
    expect(tested, <String>['front']);
    controller.dispose();
  });
}
