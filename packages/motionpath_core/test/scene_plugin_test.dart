import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('preserves nonempty overlay fields', () {
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
    expect(
      (patch['overlay']! as Map<String, Object?>).containsKey(''),
      isFalse,
    );
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
}
