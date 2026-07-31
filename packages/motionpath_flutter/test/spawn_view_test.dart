import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _child(String id) => MotionPathTrackRuntime(
      id,
      properties: <String, List<MotionPathStop>>{
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 100),
        ],
        'opacity': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 1),
          MotionPathStop(progress: 1, value: 0),
        ],
      },
    );

void main() {
  testWidgets('renders live instances with stable ids and composed patches',
      (WidgetTester tester) async {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
      childDuration: 10,
    );
    controller.spawn(_child('a'));
    controller.spawn(_child('b'), stagger: 5);

    await tester.pumpWidget(
      MotionPathSpawnView(
        controller: controller,
        itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) =>
            SizedBox(key: ValueKey<String>('content-${instance.id}')),
      ),
    );

    expect(find.byKey(const ValueKey<String>('content-a')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('content-b')), findsOneWidget);
    expect(find.byType(Stack), findsOneWidget);
    expect(find.byType(Transform), findsNothing);

    controller.advanceTo(5);
    await tester.pump();

    expect(find.byType(Transform), findsWidgets);
    expect(find.byType(Opacity), findsWidgets);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('removes a drained instance without affecting survivors',
      (WidgetTester tester) async {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
      childDuration: 1,
      drainOnComplete: true,
    );
    controller.spawn(_child('first'));
    controller.spawn(_child('second'), stagger: 10);

    await tester.pumpWidget(
      MotionPathSpawnView(
        controller: controller,
        itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) =>
            Text(instance.id),
      ),
    );
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);

    controller.advanceTo(1);
    await tester.pump();

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(controller.instances.single.id, 'second');
    controller.dispose();
  });
}
