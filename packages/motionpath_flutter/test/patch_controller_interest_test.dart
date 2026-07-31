import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _linearTrack(String id, double to) {
  return MotionPathTrackRuntime(
    id,
    properties: <String, List<MotionPathStop>>{
      'x': <MotionPathStop>[
        const MotionPathStop(progress: 0, value: 0),
        MotionPathStop(progress: 1, value: to),
      ],
    },
  );
}

MotionPathMotionRuntime _twoTrackMotion() {
  return MotionPathMotionRuntime(
    id: 'motion',
    tracks: <MotionPathTrackRuntime>[
      _linearTrack('a', 100),
      _linearTrack('b', 200),
    ],
  );
}

double _x(Map<String, Object?> patch) => (patch['x']! as num).toDouble();

void main() {
  group('interest-scoped composition', () {
    test('composes only watched tracks when nothing watches the whole graph',
        () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );
      final ValueListenable<Map<String, Object?>> a =
          controller.trackPatch('a');
      final ValueListenable<Map<String, Object?>> b =
          controller.trackPatch('b');
      int aNotifications = 0;
      void onA() => aNotifications++;
      a.addListener(onA);

      controller.tick(0.5);

      expect(aNotifications, 1);
      expect(_x(a.value), closeTo(50, 1e-9));
      // 'b' has a notifier but no listener, so it is not interesting and must
      // not have been recomposed.
      expect(_x(b.value), closeTo(0, 1e-9));

      a.removeListener(onA);
      controller.dispose();
    });

    test('a whole-graph listener still receives the full map', () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );
      int wholeGraphNotifications = 0;
      controller.addListener(() => wholeGraphNotifications++);
      final ValueListenable<Map<String, Object?>> a =
          controller.trackPatch('a');
      a.addListener(() {});

      controller.tick(0.5);

      expect(wholeGraphNotifications, 1);
      expect(controller.patches.keys, <String>['a', 'b']);
      expect(_x(controller.patchFor('a')), closeTo(50, 1e-9));
      expect(_x(controller.patchFor('b')), closeTo(100, 1e-9));
      expect(_x(a.value), closeTo(50, 1e-9));

      controller.dispose();
    });

    test('a filtered composition leaves the core full-graph snapshot alone', () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );
      controller.trackPatch('a').addListener(() {});

      controller.tick(0.5);

      expect(_x(motion.patches['a']!), closeTo(0, 1e-9));
      expect(_x(motion.patches['b']!), closeTo(0, 1e-9));

      controller.dispose();
    });
  });

  group('listener gating', () {
    test('a tick with no listeners advances time without composing', () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );

      controller.tick(0.5);

      expect(motion.progress, closeTo(0.5, 1e-9));
      expect(_x(controller.patchFor('a')), closeTo(0, 1e-9));
      expect(controller.hasAnyListener, isFalse);

      controller.dispose();
    });

    test('imperative seek and publish compose even with no listeners', () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );

      controller.seek(0.5);
      expect(_x(controller.patchFor('a')), closeTo(50, 1e-9));

      motion.seek(1);
      controller.publish();
      expect(_x(controller.patchFor('a')), closeTo(100, 1e-9));

      controller.dispose();
    });

    test('one tick composes the graph exactly once', () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      int publishes = 0;
      motion.onPatches = (_) => publishes++;
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );
      controller.addListener(() {});

      controller.tick(0.5);

      expect(publishes, 1);

      controller.dispose();
    });
  });

  group('dirty checking', () {
    test('an unchanged patch does not renotify a track listener', () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );
      int notifications = 0;
      controller.trackPatch('a').addListener(() => notifications++);

      controller.seek(0.5);
      expect(notifications, 1);

      controller.seek(0.5);
      expect(notifications, 1);

      controller.seek(0.75);
      expect(notifications, 2);

      controller.dispose();
    });

    test('deep equality sees through nested payloads', () {
      expect(
        motionPathPatchEquals(
          <String, Object?>{
            'filter': <String, Object?>{'blur': 4},
          },
          <String, Object?>{
            'filter': <String, Object?>{'blur': 4},
          },
        ),
        isTrue,
      );
      expect(
        motionPathPatchEquals(
          <String, Object?>{
            'filter': <String, Object?>{'blur': 4},
          },
          <String, Object?>{
            'filter': <String, Object?>{'blur': 8},
          },
        ),
        isFalse,
      );
      expect(
        motionPathPatchEquals(
          <String, Object?>{
            'instances': <Object?>[
              <String, Object?>{'id': 'one'},
            ],
          },
          <String, Object?>{
            'instances': <Object?>[
              <String, Object?>{'id': 'two'},
            ],
          },
        ),
        isFalse,
      );
      expect(
        motionPathPatchEquals(double.nan, double.nan),
        isTrue,
      );
    });
  });

  group('notifier lifecycle', () {
    test('released track patches do not accumulate', () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );

      for (int cycle = 0; cycle < 50; cycle++) {
        controller.trackPatch('spawned-$cycle');
        controller.releaseTrackPatch('spawned-$cycle');
      }

      expect(controller.debugTrackPatchCount, 0);

      controller.dispose();
    });

    test('a notifier registered before its first composition survives', () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );
      controller.trackPatch('not-yet-composed');
      controller.addListener(() {});

      controller.tick(0.5);
      controller.tick(0.5);

      expect(controller.debugTrackPatchCount, 1);

      controller.dispose();
    });

    test('dispose tears down every per-track notifier once', () {
      final MotionPathMotionRuntime motion = _twoTrackMotion();
      final MotionPathPatchController controller = MotionPathPatchController(
        motion: motion,
      );
      controller.trackPatch('a');
      controller.trackPatch('b');

      controller.dispose();
      controller.dispose();

      expect(controller.debugTrackPatchCount, 0);
    });
  });
}
