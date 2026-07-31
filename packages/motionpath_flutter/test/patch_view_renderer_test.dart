import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

class _BuildCounter extends StatefulWidget {
  const _BuildCounter({required this.onBuild});

  final VoidCallback onBuild;

  @override
  State<_BuildCounter> createState() => _BuildCounterState();
}

class _BuildCounterState extends State<_BuildCounter> {
  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return const SizedBox(width: 20, height: 20);
  }
}

void main() {
  testWidgets('reuses the expensive child across patch notifications',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    int builds = 0;
    await tester.pumpWidget(
      MotionPathPatchView(
        source: source,
        trackId: 'card',
        child: _BuildCounter(onBuild: () => builds++),
      ),
    );
    expect(builds, 1);

    source.publish(<String, Map<String, Object?>>{
      'card': <String, Object?>{'x': 10, 'opacity': 0.5},
    });
    await tester.pump();
    source.publish(<String, Map<String, Object?>>{
      'card': <String, Object?>{'x': 20, 'opacity': 1},
    });
    await tester.pump();

    expect(builds, 1);
    expect(find.byType(Transform), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('applies blur through the shared patch consumer',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    await tester.pumpWidget(
      MotionPathPatchView(
        source: source,
        trackId: 'card',
        child: const SizedBox(width: 20, height: 20),
      ),
    );
    source.publish(<String, Map<String, Object?>>{
      'card': <String, Object?>{
        'filter': <String, Object?>{'blur': 4},
      },
    });
    await tester.pump();

    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('diagnostic mode remains explicit and functional',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    await tester.pumpWidget(
      MotionPathPatchView(
        source: source,
        trackId: 'card',
        child: const SizedBox.shrink(),
        useDiagnosticPainter: true,
      ),
    );

    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
