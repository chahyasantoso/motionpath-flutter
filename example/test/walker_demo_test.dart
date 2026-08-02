import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/walker_demo.dart';

void main() {
  testWidgets('Walker host mounts the real FK graph and scrubs from scroll',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WalkerDemoPage()));
    await tester.pump();

    expect(find.text('MotionPath Walker'), findsOneWidget);
    expect(find.byType(MotionPathWalkerScene), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
