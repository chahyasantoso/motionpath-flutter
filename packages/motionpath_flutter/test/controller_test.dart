import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

Map<String, Object?> _hold(num value) => <String, Object?>{
      'stops': <Object?>[
        <String, Object?>{'p': 0, 'v': value},
        <String, Object?>{'p': 1, 'v': value},
      ],
    };

Map<String, Object?> _ramp(num from, num to) => <String, Object?>{
      'stops': <Object?>[
        <String, Object?>{'p': 0, 'v': from},
        <String, Object?>{'p': 1, 'v': to},
      ],
    };

MotionPathMotionRuntime _mountRig(MotionPathEngine engine) {
  engine.loadProject(MotionPathProject.fromJson(<String, Object?>{
    'schemaVersion': 4,
    'motions': <Object?>[
      <String, Object?>{
        'id': 'rig',
        'trigger': <String, Object?>{'type': 'time'},
        'tracks': <Object?>[
          <String, Object?>{
            'id': 'root',
            'duration': 1,
            'keyframes': <String, Object?>{
              'x': _ramp(0, 100),
              'y': _hold(0),
              'rotation': _hold(0),
            },
          },
          <String, Object?>{
            'id': 'bone',
            'duration': 1,
            'observes': <Object?>[
              <String, Object?>{
                'source': 'root',
                'role': 'input',
                'target': 'parentWorld',
              },
            ],
            'keyframes': <String, Object?>{
              'boneLength': _hold(50),
              'boneRotation': _hold(0),
            },
          },
        ],
      },
    ],
  }));
  return engine.mountMotion('rig');
}

void main() {
  test('publishes composed patches on seek', () {
    final MotionPathEngine engine = MotionPathEngine();
    final MotionPathPatchController controller =
        MotionPathPatchController(motion: _mountRig(engine));
    int notifications = 0;
    controller.addListener(() => notifications += 1);

    controller.seek(1);
    expect(controller.patchFor('root')['x'], 100);
    expect(controller.patchFor('bone')['x'], 150);
    expect(notifications, 1);

    controller.dispose();
    engine.destroy();
  });

  test('advances the motion from a single tick source', () {
    final MotionPathEngine engine = MotionPathEngine();
    final MotionPathMotionRuntime motion = _mountRig(engine)..play();
    final MotionPathPatchController controller =
        MotionPathPatchController(motion: motion);
    controller.tick(0.5);
    expect(motion.progress, 0.5);
    expect(controller.patchFor('root')['x'], 50);
    controller.dispose();
    engine.destroy();
  });

  test('an unknown track resolves to an empty patch', () {
    final MotionPathEngine engine = MotionPathEngine();
    final MotionPathPatchController controller =
        MotionPathPatchController(motion: _mountRig(engine));
    expect(controller.patchFor('ghost'), isEmpty);
    controller.dispose();
    engine.destroy();
  });

  testWidgets('repaints a rig without rebuilding the whole tree',
      (WidgetTester tester) async {
    final MotionPathEngine engine = MotionPathEngine();
    final MotionPathPatchController controller =
        MotionPathPatchController(motion: _mountRig(engine));
    int builds = 0;

    await tester.pumpWidget(
      Center(
        child: ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, Widget? child) {
            builds += 1;
            return CustomPaint(
              size: const Size(300, 300),
              painter: MotionPathRigPainter(
                patches: controller.patches,
                bones: const <MotionPathBone>[
                  MotionPathBone(parent: 'root', child: 'bone'),
                ],
                origin: const Offset(20, 150),
              ),
            );
          },
        ),
      ),
    );
    expect(builds, 1);
    expect(tester.takeException(), isNull);

    controller.seek(1);
    await tester.pump();
    expect(builds, 2);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    engine.destroy();
  });
}
