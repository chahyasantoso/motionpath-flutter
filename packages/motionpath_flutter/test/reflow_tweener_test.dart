import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _child(String id) => MotionPathTrackRuntime(id);

void main() {
  test('reflow tween advances from the settled offset with authored easing', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
      reflowDuration: 1,
      reflowEase: resolveEasing('none'),
    );
    controller.spawn(_child('a'), stagger: 10);
    controller.spawn(_child('b'), stagger: 10);
    controller.spawn(_child('c'), stagger: 10);

    controller.remove('b');
    expect(controller.instances[1].id, 'c');
    expect(controller.instances[1].offset, 20);

    controller.advanceBy(0.5);
    expect(controller.instances[1].offset, closeTo(15, 1e-9));

    controller.advanceBy(0.5);
    expect(controller.instances[1].offset, 10);
    controller.dispose();
  });
}
