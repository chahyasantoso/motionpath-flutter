import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('samples a normalized polyline into x and y', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'path',
      properties: <String, List<MotionPathStop>>{
        'path': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: <Object?>[
            <String, Object?>{'x': 0, 'y': 0},
            <String, Object?>{'x': 10, 'y': 0},
            <String, Object?>{'x': 10, 'y': 10},
          ]),
          MotionPathStop(progress: 1, value: <Object?>[
            <String, Object?>{
              'x': 0,
              'y': 0,
            },
            <String, Object?>{
              'x': 10,
              'y': 0,
            },
            <String, Object?>{
              'x': 10,
              'y': 10,
            },
          ]),
        ],
      },
      plugins: <MotionPathPlugin>[pathPlugin],
    );
    track.seek(0.75);
    final Map<String, Object?> patch = track.compose();
    expect(patch['x'], closeTo(10, 1e-9));
    expect(patch['y'], closeTo(5, 1e-9));
    expect(patch.containsKey('path'), isFalse);
  });
}
