import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathSpawnInstance _instance(
  String id,
  double offset,
  double z,
) => MotionPathSpawnInstance(
      id: id,
      offset: offset,
      progress: 0,
      hasStarted: false,
      patch: <String, Object?>{'z': z},
    );

void main() {
  test('sorts explicit depth back-to-front and preserves equal-depth order', () {
    final List<MotionPathSpawnInstance> input = <MotionPathSpawnInstance>[
      _instance('near', 0, 20),
      _instance('far', 5, -20),
      _instance('tie-a', 10, 0),
      _instance('tie-b', 15, 0),
    ];

    expect(
      motionPathPaintOrder(input).map((MotionPathSpawnInstance item) => item.id),
      <String>['far', 'tie-a', 'tie-b', 'near'],
    );
    expect(
      motionPathTopMostFirst(input).map((MotionPathSpawnInstance item) => item.id),
      <String>['near', 'tie-b', 'tie-a', 'far'],
    );
    expect(
      motionPathHitTest(input, (MotionPathSpawnInstance _) => true)?.id,
      'near',
    );
  });

  testWidgets('paints explicit depth order and applies Matrix4 transforms',
      (WidgetTester tester) async {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
    );
    controller.spawn(
      MotionPathTrackRuntime(
        'near',
        properties: <String, List<MotionPathStop>>{
          'z': const <MotionPathStop>[
            MotionPathStop(progress: 0, value: 20),
            MotionPathStop(progress: 1, value: 20),
          ],
        },
      ),
    );
    controller.spawn(
      MotionPathTrackRuntime(
        'far',
        properties: <String, List<MotionPathStop>>{
          'z': const <MotionPathStop>[
            MotionPathStop(progress: 0, value: -20),
            MotionPathStop(progress: 1, value: -20),
          ],
        },
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MotionPathSpawnView(
          controller: controller,
          itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) =>
              SizedBox(key: ValueKey<String>('content-${instance.id}')),
        ),
      ),
    );

    final Stack stack = tester.widget<Stack>(find.byType(Stack));
    final List<String> ids = <String>[
      for (final Widget child in stack.children)
        (child.key! as ValueKey<String>).value,
    ];
    expect(ids, <String>['far', 'near']);
    expect(find.byType(Transform), findsNWidgets(2));

    controller.dispose();
  });
}
