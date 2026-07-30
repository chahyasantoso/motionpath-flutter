import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('patch painter accepts renderer-neutral transform fields', () {
    final painter = MotionPathPatchPainter(patch: const <String, Object?>{'x': 10, 'opacity': 0.5});
    expect(painter.shouldRepaint(MotionPathPatchPainter(patch: const <String, Object?>{'x': 10, 'opacity': 0.5})), isTrue);
  });
}
