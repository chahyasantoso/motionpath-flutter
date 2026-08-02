import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/pasar_malam_observer_demo.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  testWidgets('observer host mounts the story and self-driving lantern loop', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasarMalamObserverDemoPage()));
    await tester.pump();
    expect(find.text('MotionPath Pasar Malam Observer'), findsOneWidget);
    expect(find.text('Pasar Malam'), findsOneWidget);
    expect(find.byType(MotionPathSpawnView), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('observer host scrubs story without using scroll for the bounce', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasarMalamObserverDemoPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('OBSERVER FRAME 0049'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('observer host tears down both timelines', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasarMalamObserverDemoPage()));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    expect(find.byType(PasarMalamObserverDemoPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
