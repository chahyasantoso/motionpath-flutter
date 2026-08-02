import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/pasar_malam_demo.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  testWidgets('Pasar Malam mounts the authored storytelling host', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasarMalamDemoPage()));
    await tester.pump();

    expect(find.text('MotionPath Pasar Malam'), findsOneWidget);
    expect(find.text('Pasar Malam'), findsOneWidget);
    expect(find.text('Nostalgic Tastes'), findsOneWidget);
    expect(find.text('Carnival Thrills'), findsOneWidget);
    expect(find.text('192-frame night market sequence'), findsOneWidget);
    expect(find.byType(MotionPathSpawnView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pasar Malam scrubs forward and returns to start', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasarMalamDemoPage()));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('FRAME 0049'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('FRAME 0001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pasar Malam tears down scroll and spawn wiring', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasarMalamDemoPage()));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    expect(find.byType(PasarMalamDemoPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
