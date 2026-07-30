import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathRigPainter _painter(double childX) => MotionPathRigPainter(
      patches: <String, Map<String, Object?>>{
        'root': <String, Object?>{'x': 0, 'y': 0, 'rotation': 0},
        'bone': <String, Object?>{'x': childX, 'y': 0, 'rotation': 0},
      },
      bones: const <MotionPathBone>[
        MotionPathBone(parent: 'root', child: 'bone'),
      ],
    );

void main() {
  test('reads joint positions out of composed patches', () {
    expect(_painter(40).jointFor('bone'), const Offset(40, 0));
    expect(_painter(40).jointFor('ghost'), isNull);
  });

  test('repaints only when rig geometry changes', () {
    expect(_painter(40).shouldRepaint(_painter(40)), isFalse);
    expect(_painter(40).shouldRepaint(_painter(41)), isTrue);
  });

  testWidgets('paints a rig without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: CustomPaint(
          size: const Size(200, 200),
          painter: _painter(60),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
