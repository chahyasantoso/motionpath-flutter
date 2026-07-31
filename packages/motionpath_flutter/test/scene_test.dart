import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

Map<String, Object?> _project() => <String, Object?>{
  'schemaVersion': 4,
  'projectId': 'scene',
  'motions': <Object?>[
    <String, Object?>{
      'id': 'rig',
      'trigger': <String, Object?>{'type': 'manual'},
      'tracks': <Object?>[
        <String, Object?>{
          'id': 'root',
          'keyframes': <String, Object?>{
            'x': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': 0},
                <String, Object?>{'p': 1, 'v': 100},
              ],
            },
          },
        },
        <String, Object?>{
          'id': 'bone',
          'observes': <Object?>[
            <String, Object?>{
              'source': 'root',
              'role': 'input',
              'target': 'parentWorld',
            },
          ],
          'keyframes': <String, Object?>{
            'boneLength': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': 10},
                <String, Object?>{'p': 1, 'v': 10},
              ],
            },
          },
        },
      ],
    },
  ],
};

void main() {
  test('maps scroll offsets onto normalized progress', () {
    const MotionPathScrollBinding binding = MotionPathScrollBinding(
      start: 100,
      end: 500,
    );
    expect(binding.progressFor(0), 0);
    expect(binding.progressFor(300), closeTo(0.5, 1e-9));
    expect(binding.progressFor(900), 1);
  });

  test('eases toward the target only when scrub is authored', () {
    const MotionPathScrollBinding smoothed = MotionPathScrollBinding(
      scrub: 0.5,
    );
    final double stepped = smoothed.scrubToward(0, 1, 0.1);
    expect(stepped, greaterThan(0));
    expect(stepped, lessThan(1));
    expect(const MotionPathScrollBinding().scrubToward(0, 1, 0.1), 1);
  });

  testWidgets('a scroll driver reports progress from a controller', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = ScrollController();
    final List<double> seen = <double>[];
    final MotionPathScrollDriver driver = MotionPathScrollDriver(
      binding: const MotionPathScrollBinding(end: 400),
      onProgress: seen.add,
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          controller: controller,
          itemCount: 40,
          itemBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 100),
        ),
      ),
    );
    driver.attach(controller);
    expect(seen.last, 0);
    controller.jumpTo(200);
    await tester.pump();
    expect(seen.last, closeTo(0.5, 1e-9));
    driver.detach();
  });

  testWidgets('publishing a patch repaints the bound view', (
    WidgetTester tester,
  ) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    await tester.pumpWidget(
      Center(
        child: MotionPathPatchView(source: source, trackId: 'pelvis'),
      ),
    );
    expect(source.patchFor('pelvis'), isEmpty);
    source.publish(<String, Map<String, Object?>>{
      'pelvis': <String, Object?>{'x': 12.0, 'opacity': 0.5},
    });
    await tester.pump();
    expect(source.patchFor('pelvis')['x'], 12.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an engine tick drives composed FK patches into the painter', (
    WidgetTester tester,
  ) async {
    final MotionPathEngine engine = MotionPathEngine()
      ..loadProject(MotionPathProject.fromJson(_project()));
    final MotionPathMotionRuntime motion = engine.mountMotion('rig')..play();
    final MotionPathPatchSource source = MotionPathPatchSource()..bind(motion);
    await tester.pumpWidget(
      Center(
        child: MotionPathPatchView(source: source, trackId: 'bone'),
      ),
    );
    engine.tick(0.5);
    await tester.pump();
    expect(
      (source.patchFor('bone')['x']! as num).toDouble(),
      closeTo(60, 1e-9),
    );
    expect(source.patchFor('bone').keys, isNot(contains('parentWorld')));
    expect(tester.takeException(), isNull);
    engine.destroy();
  });
}
