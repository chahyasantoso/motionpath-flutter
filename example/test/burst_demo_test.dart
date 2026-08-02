import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';
import 'package:motionpath_flutter_example/burst_demo.dart';

double _opacityFor(WidgetTester tester, String label) {
  final Finder finder = find.ancestor(
    of: find.text(label),
    matching: find.byType(Opacity),
  );
  if (finder.evaluate().isEmpty) return 1;
  return tester.widget<Opacity>(finder.first).opacity;
}

void main() {
  testWidgets('Burst host mounts every authored card through the spawn view',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BurstDemoPage()));
    await tester.pump();

    expect(find.byType(BurstDemoPage), findsOneWidget);
    expect(find.text('BERRY 1'), findsOneWidget);
    expect(find.text('BERRY 10'), findsOneWidget);
    expect(find.text('ICE CREAM'), findsOneWidget);
    expect(find.text('scroll-driven burst'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MotionPathSpawnView),
        matching: find.byType(Transform),
      ),
      findsNWidgets(11),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Burst cards stay hidden at rest and fade in on scroll',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BurstDemoPage()));
    await tester.pump();

    expect(_opacityFor(tester, 'BERRY 1'), 0);
    expect(_opacityFor(tester, 'ICE CREAM'), 0);

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(_opacityFor(tester, 'BERRY 1'), greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Burst host returns to the authored start when scrolled back',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BurstDemoPage()));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 240));
    await tester.pumpAndSettle();

    expect(_opacityFor(tester, 'BERRY 1'), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Burst host tears down its scroll and spawn wiring',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BurstDemoPage()));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(find.byType(BurstDemoPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
