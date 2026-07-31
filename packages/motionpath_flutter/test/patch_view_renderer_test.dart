import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  testWidgets('applies patch transforms without rebuilding the child identity',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    const Key childKey = ValueKey<String>('stable-child');
    await tester.pumpWidget(
      MotionPathPatchView(
        source: source,
        trackId: 'card',
        child: const SizedBox(key: childKey, width: 20, height: 20),
      ),
    );
    expect(find.byKey(childKey), findsOneWidget);

    source.publish(<String, Map<String, Object?>>{
      'card': <String, Object?>{'x': 20, 'opacity': 0.5},
    });
    await tester.pump();

    expect(find.byKey(childKey), findsOneWidget);
    expect(find.byType(Transform), findsOneWidget);
    expect(find.byType(Opacity), findsOneWidget);
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

  testWidgets('diagnostic mode is explicit', (WidgetTester tester) async {
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
