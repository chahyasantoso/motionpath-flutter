import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/motorcycle_demo.dart';

const String _artPrefix = 'moto-art-';

Finder _art(String id) => find.byKey(ValueKey<String>('$_artPrefix$id'));

/// Art ids in depth-first tree order, which is Stack paint order.
List<String> _paintedIds(WidgetTester tester) => <String>[
      for (final Element element in find
          .byWidgetPredicate(
            (Widget widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(_artPrefix),
          )
          .evaluate())
        (element.widget.key! as ValueKey<String>).value.substring(
              _artPrefix.length,
            ),
    ];

double _opacityFor(WidgetTester tester, String id) {
  final Finder finder = find.ancestor(
    of: _art(id),
    matching: find.byType(Opacity),
  );
  if (finder.evaluate().isEmpty) return 1;
  return tester.widget<Opacity>(finder.first).opacity;
}

void main() {
  testWidgets(
      'Motorcycle host mounts every authored track through the spawn view',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MotorcycleDemoPage()));
    await tester.pump();

    expect(find.byType(MotorcycleDemoPage), findsOneWidget);
    expect(find.text('scroll-driven ride'), findsOneWidget);
    for (final String id in motorcyclePaintOrder) {
      expect(_art(id), findsOneWidget, reason: 'missing host art for $id');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Motorcycle paints clouds and streaks behind the rider',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MotorcycleDemoPage()));
    await tester.pump();

    expect(_paintedIds(tester), motorcyclePaintOrder);
    expect(motorcyclePaintOrder.last, 'moto-bike');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Motorcycle stays hidden at rest and rides in on scroll',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MotorcycleDemoPage()));
    await tester.pump();

    expect(_opacityFor(tester, 'moto-bike'), 0);
    expect(_opacityFor(tester, 'moto-shadow'), 0);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(_opacityFor(tester, 'moto-bike'), greaterThan(0));
    expect(_opacityFor(tester, 'moto-shadow'), greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Motorcycle returns to the authored start when scrolled back',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MotorcycleDemoPage()));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(_opacityFor(tester, 'moto-bike'), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Motorcycle host tears down its scroll and spawn wiring',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MotorcycleDemoPage()));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(find.byType(MotorcycleDemoPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
