import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _child(String id) => MotionPathTrackRuntime(id);

void main() {
  testWidgets('host callback receives only the front-most matching instance',
      (WidgetTester tester) async {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
    );
    controller.spawn(_child('back'));
    controller.spawn(_child('front'), stagger: 10);
    String? hit;

    await tester.pumpWidget(
      MotionPathSpawnView(
        controller: controller,
        onHit: (MotionPathSpawnInstance instance, Offset position) {
          hit = instance.id;
          return true;
        },
        itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) =>
            const SizedBox.expand(),
      ),
    );
    await tester.tap(find.byType(GestureDetector));

    expect(hit, 'front');
    controller.dispose();
  });
}
