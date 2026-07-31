import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('reads renderer-neutral transform keys from a patch', () {
    final MotionPathPatchTransform transform =
        MotionPathPatchTransform.fromPatch(const <String, Object?>{
          'x': 10,
          'y': -4,
          'scale': 2,
          'opacity': 0.5,
          'color': 0xFF00FF00,
        });
    expect(transform.translateX, 10);
    expect(transform.translateY, -4);
    expect(transform.scaleX, 2);
    expect(transform.scaleY, 2);
    expect(transform.opacity, 0.5);
    expect(transform.color, const Color(0x8000FF00));
  });

  test('falls back to identity values and the fallback colour', () {
    final MotionPathPatchTransform transform =
        MotionPathPatchTransform.fromPatch(const <String, Object?>{});
    expect(transform, const MotionPathPatchTransform());
    expect(transform.argb, kMotionPathDefaultArgb);
  });

  test('builds column-major scale, rotate, translate storage', () {
    final Float64List storage = const MotionPathPatchTransform(
      translateX: 5,
      translateY: 7,
      scaleX: 2,
      scaleY: 3,
    ).toMatrix4Storage();
    expect(storage[0], 2);
    expect(storage[5], 3);
    expect(storage[12], 5);
    expect(storage[13], 7);
    expect(storage[15], 1);
  });

  test('repaints only when the patch content changes', () {
    final MotionPathPatchPainter painter = MotionPathPatchPainter(
      patch: <String, Object?>{'x': 10},
    );
    expect(
      painter.shouldRepaint(
        MotionPathPatchPainter(patch: <String, Object?>{'x': 10}),
      ),
      isFalse,
    );
    expect(
      painter.shouldRepaint(
        MotionPathPatchPainter(patch: <String, Object?>{'x': 11}),
      ),
      isTrue,
    );
  });

  testWidgets('paints a composed patch without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Center(
        child: CustomPaint(
          size: const Size(200, 200),
          painter: MotionPathPatchPainter(
            patch: const <String, Object?>{
              'x': 12,
              'rotation': 0.5,
              'opacity': 0.75,
            },
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
