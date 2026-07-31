import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

class _BuildProbe extends StatefulWidget {
  const _BuildProbe({required this.builds});

  final ValueNotifier<int> builds;

  @override
  State<_BuildProbe> createState() => _BuildProbeState();
}

class _BuildProbeState extends State<_BuildProbe> {
  @override
  Widget build(BuildContext context) {
    widget.builds.value++;
    return const SizedBox();
  }
}

void main() {
  testWidgets('250 patch updates do not rebuild the supplied child',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    final ValueNotifier<int> builds = ValueNotifier<int>(0);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MotionPathPatchView(
          source: source,
          trackId: 'card',
          child: _BuildProbe(builds: builds),
        ),
      ),
    );

    final int initialBuilds = builds.value;
    for (int frame = 0; frame < 250; frame++) {
      source.publish(<String, Map<String, Object?>>{
        'card': <String, Object?>{
          'x': frame,
          'opacity': 0.5 + (frame % 50) / 100,
          'filter': <String, Object?>{'blur': frame % 8},
          'instances': <Object?>[
            <String, Object?>{'id': 'card', 'frame': frame},
          ],
        },
      });
      await tester.pump();
    }

    expect(builds.value, initialBuilds);
    expect(find.byType(Transform), findsWidgets);
    expect(tester.takeException(), isNull);
    builds.dispose();
  });

  test('deep dirty checking distinguishes nested renderer payloads', () {
    final Map<String, Object?> before = <String, Object?>{
      'filter': <String, Object?>{'blur': 2},
      'instances': <Object?>[
        <String, Object?>{'id': 'one', 'frame': 1},
      ],
    };
    final Map<String, Object?> after = <String, Object?>{
      'filter': <String, Object?>{'blur': 2},
      'instances': <Object?>[
        <String, Object?>{'id': 'one', 'frame': 2},
      ],
    };

    expect(motionPathPatchEquals(before, before), isTrue);
    expect(motionPathPatchEquals(before, after), isFalse);
  });
}
