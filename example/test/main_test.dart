import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/main.dart';

void main() {
  testWidgets('launcher exposes every ported demo', (WidgetTester tester) async {
    await tester.pumpWidget(const MotionPathExampleApp());
    await tester.pump();

    expect(find.byType(DemoLauncherPage), findsOneWidget);
    expect(find.text('MotionPath demos'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.apps));
    await tester.pumpAndSettle();

    for (final String title in <String>[
      'Walker',
      'Burst',
      'Motorcycle',
      'Helix',
      'Carousel',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('launcher switches demos from the drawer',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MotionPathExampleApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.apps));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Motorcycle', skipOffstage: false));
    await tester.pump();

    expect(find.text('MotionPath Motorcycle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
