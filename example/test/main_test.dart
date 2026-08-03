import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/main.dart';

void main() {
  testWidgets('launcher exposes every ported demo', (WidgetTester tester) async {
    await tester.pumpWidget(const MotionPathExampleApp());
    await tester.pump();
    expect(find.byType(DemoLauncherPage), findsOneWidget);
    await tester.tap(find.byIcon(Icons.apps));
    await tester.pumpAndSettle();
    for (final String title in <String>[
      'Walker', 'Burst', 'Motorcycle', 'Pasar Malam',
      'Pasar Malam Observer', 'Tower Defense', 'Hooks Demo', 'Helix', 'Carousel',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('launcher switches into the new hosts', (WidgetTester tester) async {
    await tester.pumpWidget(const MotionPathExampleApp());
    await tester.pump();
    for (final String selection in <String>['Pasar Malam', 'Tower Defense', 'Hooks Demo']) {
      await tester.tap(find.byIcon(Icons.apps));
      await tester.pumpAndSettle();
      await tester.tap(find.text(selection, skipOffstage: false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('MotionPath'), findsWidgets);
    }
  });
}
