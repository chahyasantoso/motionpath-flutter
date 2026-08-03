import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _child(String id) => MotionPathTrackRuntime(id);

Widget _content(String label) => SizedBox(
      key: ValueKey<String>('content-$label'),
      child: Text(label),
    );

Widget _host({
  required MotionPathSpawnController controller,
  required MotionPathSpawnItemBuilder itemBuilder,
}) => Directionality(
      textDirection: TextDirection.ltr,
      child: MotionPathSpawnView(
        controller: controller,
        itemBuilder: itemBuilder,
      ),
    );

void main() {
  testWidgets('controller replacement drops cached children', (WidgetTester tester) async {
    final MotionPathSpawnController first = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('first-parent'),
    )..spawn(_child('same'));
    final MotionPathSpawnController second = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('second-parent'),
    )..spawn(_child('same'));

    await tester.pumpWidget(
      _host(
        controller: first,
        itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) =>
            _content('first'),
      ),
    );
    expect(find.text('first'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        controller: second,
        itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) =>
            _content('second'),
      ),
    );
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(tester.takeException(), isNull);
    first.dispose();
    second.dispose();
  });

  testWidgets('builder replacement does not reuse cached child widgets', (WidgetTester tester) async {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('parent'),
    )..spawn(_child('same'));

    Widget buildFirst(BuildContext context, MotionPathSpawnInstance instance) =>
        _content('first');
    Widget buildSecond(BuildContext context, MotionPathSpawnInstance instance) =>
        _content('second');

    await tester.pumpWidget(
      _host(controller: controller, itemBuilder: buildFirst),
    );
    expect(find.text('first'), findsOneWidget);

    await tester.pumpWidget(
      _host(controller: controller, itemBuilder: buildSecond),
    );
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
