import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _child(String id) => MotionPathTrackRuntime(id);

void main() {
  testWidgets('paints ascending snapshots so the top-most child is last',
      (WidgetTester tester) async {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
    );
    controller.spawn(_child('first'));
    controller.spawn(_child('second'), stagger: 5);
    controller.spawn(_child('third'), stagger: 5);

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
        (child.key! as ValueKey<String>).value.replaceFirst('content-', ''),
    ];
    expect(ids, <String>['first', 'second', 'third']);
    expect(
      motionPathTopMostFirst(controller.instances)
          .map((MotionPathSpawnInstance instance) => instance.id),
      <String>['third', 'second', 'first'],
    );

    controller.dispose();
  });
}
