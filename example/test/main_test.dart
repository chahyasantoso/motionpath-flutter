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
      'Pasar Malam Observer', 'Tower Defense', 'Hooks Demo',
      'Spiral / Zuma', 'Helix', 'Carousel',
    ]) {
      expect(find.text(title, skipOffstage: false), findsOneWidget);
    }
  });

  testWidgets('launcher switches into the new hosts', (WidgetTester tester) async {
    await tester.pumpWidget(const MotionPathExampleApp());
    await tester.pump();
    for (final String selection in <String>[
      'Pasar Malam', 'Tower Defense', 'Hooks Demo', 'Spiral / Zuma',
    ]) {
      await tester.tap(find.byIcon(Icons.apps));
      await tester.pumpAndSettle();
      final Finder target = find.text(selection, skipOffstage: false);
      await tester.ensureVisible(target);
      await tester.pump();
      await tester.tap(target);
      // Self-driving hosts keep a ticker running for as long as they are
      // mounted, so the tree never reaches a settled frame. Pump a bounded
      // number of frames to finish the drawer dismissal instead of settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.textContaining('MotionPath'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });
}
