import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('emits only valid CSS custom properties', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'styles',
      properties: <String, List<MotionPathStop>>{
        'cssVariables': const <MotionPathStop>[
          MotionPathStop(
            progress: 0,
            value: <String, Object?>{'--opacity': 0, 'color': 'red'},
          ),
          MotionPathStop(
            progress: 1,
            value: <String, Object?>{'--opacity': 1, 'color': 'blue'},
          ),
        ],
      },
      plugins: <MotionPathPlugin>[cssVariablePlugin],
    );
    track.seek(0.5);
    final Map<String, Object?> patch = track.compose();
    final Map<String, Object?> variables =
        patch['cssVariables']! as Map<String, Object?>;
    expect(variables.keys, <String>['--opacity']);
    expect(variables['--opacity'], 0.5);
  });
}
