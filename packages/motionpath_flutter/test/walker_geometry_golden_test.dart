import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('walker tone styles and ground remain stable', () {
    expect(kMotionPathWalkerGroundY, 266);
    expect(kMotionPathWalkerToneOrder, <MotionPathWalkerTone>[
      MotionPathWalkerTone.far,
      MotionPathWalkerTone.core,
      MotionPathWalkerTone.near,
    ]);
    expect(kMotionPathWalkerToneStyles[MotionPathWalkerTone.core]!.thickness, 24);
    expect(kMotionPathWalkerToneStyles[MotionPathWalkerTone.near]!.thickness, 16);
    expect(kMotionPathWalkerToneStyles[MotionPathWalkerTone.far]!.opacity, 0.62);
  });

  test('resolved Walker geometry stays deterministic at a right angle', () {
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
    expect(segments.single.origin, const Offset(100, 148));
    expect(segments.single.tip, const Offset(100, 70));
    expect(segments.single.length, closeTo(78, 1e-9));
  });
}
