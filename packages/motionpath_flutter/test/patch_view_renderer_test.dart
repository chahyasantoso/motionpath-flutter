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
  testWidgets('reuses the supplied child without rebuilding it on patch updates',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    final ValueNotifier<int> builds = ValueNotifier<int>(0);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MotionPathPatchView(
        source: source,
        trackId: 'card',
        child: _BuildProbe(builds: builds),
      ),
    ));
    expect(builds.value, 1);
    source.publish(<String, Map<String, Object?>>{
      'card': <String, Object?>{'x': 20, 'scale': 1.2, 'opacity': 0.5},
    });
    await tester.pump();
    expect(builds.value, 1);
    expect(find.byType(Opacity), findsOneWidget);
    expect(find.byType(Transform), findsWidgets);
    expect(tester.takeException(), isNull);
    builds.dispose();
  });

  testWidgets('applies rotation and blur from the patch',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MotionPathPatchView(
        source: source,
        trackId: 'card',
        child: const SizedBox(),
      ),
    ));
    source.publish(<String, Map<String, Object?>>{
      'card': <String, Object?>{
        'rotation': 90,
        'filter': <String, Object?>{'blur': 4},
      },
    });
    await tester.pump();
    expect(find.byType(Transform), findsWidgets);
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('consumes color, visibility, CSS, and instance payloads',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    final ValueNotifier<int> cssCalls = ValueNotifier<int>(0);
    final ValueNotifier<int> instanceCalls = ValueNotifier<int>(0);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MotionPathPatchView(
        source: source,
        trackId: 'card',
        child: const SizedBox(),
        cssVariablesBuilder: (BuildContext context, Map<String, Object?> vars,
            Widget child) {
          cssCalls.value++;
          expect(vars['--tone'], 2);
          return child;
        },
        instancesBuilder: (BuildContext context,
            List<Map<String, Object?>> instances, Widget child) {
          instanceCalls.value++;
          expect(instances, hasLength(1));
          return child;
        },
      ),
    ));
    source.publish(<String, Map<String, Object?>>{
      'card': <String, Object?>{
        'color': 0xFFFF0000,
        'visible': false,
        'cssVariables': <String, Object?>{'--tone': 2},
        'instances': <Object?>[<String, Object?>{'id': 'one'}],
      },
    });
    await tester.pump();
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(find.byType(Offstage), findsOneWidget);
    expect(cssCalls.value, greaterThan(0));
    expect(instanceCalls.value, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps diagnostic painter opt-in', (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MotionPathPatchView(
        source: source,
        trackId: 'card',
        useDiagnosticPainter: true,
        child: const SizedBox(),
      ),
    ));
    expect(find.byType(CustomPaint), findsOneWidget);
    expect(find.byType(SizedBox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
