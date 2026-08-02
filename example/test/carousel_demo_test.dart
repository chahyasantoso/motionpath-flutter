import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/carousel_demo.dart';

void main() {
  testWidgets('Carousel mounts its cards and scrubs from scroll', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CarouselDemoPage()),
    );
    await tester.pump();

    expect(find.text('MotionPath Carousel'), findsOneWidget);
    expect(find.text('One path. Dynamic children. Zero demo-only math.'), findsOneWidget);
    expect(find.text('0% scrubbed'), findsOneWidget);
    expect(find.text('Fluid Motion Engine'), findsOneWidget);
    expect(find.text('Add a Card'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();

    expect(find.text('0% scrubbed'), findsNothing);
  });
}
