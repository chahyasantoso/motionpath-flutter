import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';
import 'package:motionpath_flutter_example/helix_demo.dart';

void main() {
  testWidgets('Helix host mounts all authored cards through the spawn view',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelixDemoPage()));
    await tester.pump();

    expect(find.byType(HelixDemoPage), findsOneWidget);
    expect(find.text('HELIX 1'), findsOneWidget);
    expect(find.text('HELIX 3'), findsOneWidget);
    expect(find.text('HELIX 5'), findsOneWidget);
    expect(find.text('z-depth + Matrix4'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MotionPathSpawnView),
        matching: find.byType(Transform),
      ),
      findsNWidgets(5),
    );
    expect(tester.takeException(), isNull);
  });
}
