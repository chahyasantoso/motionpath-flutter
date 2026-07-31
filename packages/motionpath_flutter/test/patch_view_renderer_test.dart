import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  testWidgets(
    'reuses the supplied child across patch updates',
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

      source.publish(<String, Map<String, Object?>>{
        'card': <String, Object?>{
          'x': 20,
          'scale': 1.2,
          'opacity': 0.5,
        },
      });
      await tester.pump();

      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'applies rotation and blur from the patch',
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
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeps diagnostic painter opt-in',
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
      expect(tester.takeException(), isNull);
    },
  );
}
