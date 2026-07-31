import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

MotionPathTrackRuntime _track(List<Object?> points) => MotionPathTrackRuntime(
  'path',
  properties: <String, List<MotionPathStop>>{
    'path': <MotionPathStop>[
      MotionPathStop(progress: 0, value: points),
      MotionPathStop(progress: 1, value: points),
    ],
  },
  plugins: <MotionPathPlugin>[pathPlugin],
);

void main() {
  test('samples a normalized polyline by physical distance', () {
    final MotionPathTrackRuntime track = _track(<Object?>[
      <String, Object?>{'x': 0, 'y': 0},
      <String, Object?>{'x': 10, 'y': 0},
      <String, Object?>{'x': 10, 'y': 10},
    ]);
    track.seek(0.75);
    final Map<String, Object?> patch = track.compose();
    expect(patch['x'], closeTo(10, 1e-9));
    expect(patch['y'], closeTo(5, 1e-9));
    expect(patch['z'], closeTo(0, 1e-9));
    expect(patch.containsKey('path'), isFalse);
  });

  test('elevates quadratic controls and returns z', () {
    final MotionPathTrackRuntime track = _track(<Object?>[
      <String, Object?>{'x': 0, 'y': 0, 'z': 0},
      <String, Object?>{
        'x': 10,
        'y': 0,
        'z': 10,
        'ctrlX': 5,
        'ctrlY': 10,
        'ctrlZ': 5,
      },
    ]);
    track.seek(0.5);
    final Map<String, Object?> patch = track.compose();
    expect(patch['x'], closeTo(5, 1e-6));
    expect(patch['y'], greaterThan(4));
    expect(patch['z'], closeTo(5, 1e-6));
  });

  test(
    'ignores malformed nodes and rejects paths with fewer than two points',
    () {
      final MotionPathTrackRuntime track = _track(<Object?>[
        <String, Object?>{'x': 0, 'y': 0},
        <String, Object?>{'x': 'bad', 'y': 10},
      ]);
      track.seek(0.5);
      expect(track.compose(), isEmpty);
    },
  );
}
