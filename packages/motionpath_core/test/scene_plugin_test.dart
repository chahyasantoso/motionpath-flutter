import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('preserves nonempty overlay fields and filters non-string keys', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'overlay',
      properties: <String, List<MotionPathStop>>{
        'overlay': const <MotionPathStop>[
          MotionPathStop(
            progress: 0,
            value: <String, Object?>{'slot': 'hud', '': 'drop'},
          ),
        ],
      },
      plugins: <MotionPathPlugin>[overlayPlugin],
    );
    final Map<String, Object?> patch = track.compose();
    expect((patch['overlay']! as Map<String, Object?>)['slot'], 'hud');
    expect((patch['overlay']! as Map<String, Object?>).containsKey(''), isFalse);
  });

  test('empty and malformed overlays compose no overlay output', () {
    for (final Object? value in <Object?>[null, <String, Object?>{}, 'bad']) {
      final MotionPathTrackRuntime track = MotionPathTrackRuntime(
        'overlay',
        properties: <String, List<MotionPathStop>>{
          'overlay': <MotionPathStop>[
            MotionPathStop(progress: 0, value: value),
          ],
        },
        plugins: <MotionPathPlugin>[overlayPlugin],
      );
      expect(track.compose().containsKey('overlay'), isFalse);
    }
  });

  test('expands a bounded spawner payload', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'spawner',
      properties: <String, List<MotionPathStop>>{
        'spawner': const <MotionPathStop>[
          MotionPathStop(
            progress: 0,
            value: <String, Object?>{'count': 3, 'template': 'particle'},
          ),
        ],
      },
      plugins: <MotionPathPlugin>[spawnerPlugin],
    );
    final Map<String, Object?> patch = track.compose();
    final List<Map<String, Object?>> instances =
        patch['instances']! as List<Map<String, Object?>>;
    expect(instances.length, 3);
    expect(instances.last['index'], 2);
  });

  test('spawner clamps counts and rejects unusable templates by omission', () {
    final List<Object?> values = <Object?>[
      <String, Object?>{'count': -2, 'template': 'particle'},
      <String, Object?>{'count': 1001, 'template': 'particle'},
      <String, Object?>{'count': 2},
    ];
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'spawner',
      properties: <String, List<MotionPathStop>>{
        'spawner': <MotionPathStop>[
          MotionPathStop(progress: 0, value: values.first),
          MotionPathStop(progress: 1, value: values.last),
        ],
      },
      plugins: <MotionPathPlugin>[spawnerPlugin],
    );
    expect(track.compose().containsKey('instances'), isFalse);
  });
}
