import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  testWidgets('reuses the supplied child across patch updates',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();
    const Key childKey = ValueKey<String>('stable-child');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MotionPathPatchView(
          source: source,
          trackId: 'card',
          child: const SizedBox(key: childKey),
        ),
      ),
    );

    final Element before = tester.element(find.byKey(childKey));
    source.publish(<String, Map<String, Object?>>{
      'card': <String, Object?>{
        'x': 20,
        'scale': 1.2,
        'opacity': 0.5,
      },
    });
    await tester.pump();

    expect(tester.element(find.byKey(childKey)), same(before));
    expect(find.byType(Opacity), findsOneWidget);
    expect(find.byType(Transform), findsNWidgets(2));
  });

  testWidgets('applies rotation and blur from the patch',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MotionPathPatchView(
          source: source,
          trackId: 'card',
          child: const SizedBox(),
        ),
      ),
    );

    source.publish(<String, Map<String, Object?>>{
      'card': <String, Object?>{
        'rotation': 90,
        'filter': <String, Object?>{'blur': 4},
      },
    });
    await tester.pump();

    expect(find.byType(Transform), findsOneWidget);
    expect(find.byType(ImageFiltered), findsOneWidget);
    final Transform rotation = tester.widget<Transform>(find.byType(Transform));
    expect(rotation.transform.storage[0], closeTo(0, 1e-9));
    expect(rotation.transform.storage[1], closeTo(1, 1e-9));
  });

  testWidgets('keeps diagnostic painter opt-in',
      (WidgetTester tester) async {
    final MotionPathPatchSource source = MotionPathPatchSource();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MotionPathPatchView(
          source: source,
          trackId: 'card',
          useDiagnosticPainter: true,
          child: const SizedBox(),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsOneWidget);
    expect(find.byType(SizedBox), findsNothing);
  });
}
