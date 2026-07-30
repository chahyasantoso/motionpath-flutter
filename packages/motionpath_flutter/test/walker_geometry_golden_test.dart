import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('walker tone styles and ground remain stable', () {
    expect(kMotionPathWalkerGroundY, 266);
    expect(kMotionPathWalkerToneStyles[MotionPathWalkerTone.core]!.thickness, 24);
    expect(kMotionPathWalkerToneStyles[MotionPathWalkerTone.near]!.thickness, 16);
    expect(kMotionPathWalkerToneStyles[MotionPathWalkerTone.far]!.opacity, 0.62);
  });

  test('walker segment length is preserved at a right angle', () {
    final List<MotionPathWalkerSegment> segments = resolveWalkerSegments(
      <String, Map<String, Object?>>{
        'spine': <String, Object?>{'x': 100, 'y': 148, 'rotation': -90},
      },
      bones: const <MotionPathWalkerBone>[
        MotionPathWalkerBone(
          id: 'spine',
          drawLength: 78,
          tone: MotionPathWalkerTone.core,
        ),
      ],
    );
    expect(segments, hasLength(1));
    expect(segments.single.length, closeTo(78, 1e-9));
  });
}
