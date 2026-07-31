import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('resolves z, perspective, and XYZ rotations into one matrix', () {
    final MotionPathPatchTransform transform = MotionPathPatchTransform.fromPatch(
      <String, Object?>{
        'x': 10,
        'y': 20,
        'z': 30,
        'rotation': 90,
        'rotateX': 10,
        'rotateY': 20,
        'scale': 2,
        'perspective': 0.001,
      },
    );
    final List<double> matrix = transform.toMatrix4Storage().toList();
    expect(matrix[12], 10);
    expect(matrix[13], 20);
    expect(matrix[14], 30);
    expect(matrix[15], 1);
    expect(matrix[11], -0.001);
    expect(transform.rotationRadians, closeTo(1.57079632679, 1e-9));
  });

  test('invalid transform values fall back to identity components', () {
    final MotionPathPatchTransform transform = MotionPathPatchTransform.fromPatch(
      <String, Object?>{'z': double.nan, 'perspective': double.infinity},
    );
    expect(transform.translateZ, 0);
    expect(transform.perspective, 0);
  });
}
