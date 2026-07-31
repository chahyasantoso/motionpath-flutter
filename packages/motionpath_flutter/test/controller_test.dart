import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('publishes composed patches on seek', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'motion',
      tracks: <MotionPathTrackRuntime>[
        MotionPathTrackRuntime(
          'box',
          properties: <String, List<MotionPathStop>>{
            'x': const <MotionPathStop>[
              MotionPathStop(progress: 0, value: 0),
              MotionPathStop(progress: 1, value: 100),
            ],
          },
        ),
      ],
    );
    final MotionPathPatchController controller = MotionPathPatchController(
      motion: motion,
    );
    controller.seek(0.5);
    expect(controller.patchFor('box')['x'], closeTo(50, 1e-9));
    controller.dispose();
  });

  test('dispose is idempotent and blocks later publishes', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'motion',
      tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('box')],
    );
    final MotionPathPatchController controller = MotionPathPatchController(
      motion: motion,
    );
    int notifications = 0;
    controller.addListener(() => notifications++);
    controller.dispose();
    controller.dispose();
    controller.seek(1);
    controller.tick(1);
    controller.publish();
    expect(notifications, 0);
  });
}
