import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('keeps supported numeric filters and drops unknown values', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'filters',
      properties: <String, List<MotionPathStop>>{
        'filter': const <MotionPathStop>[
          MotionPathStop(
            progress: 0,
            value: <String, Object?>{'blur': 0, 'contrast': 1, 'unknown': 9},
          ),
          MotionPathStop(
            progress: 1,
            value: <String, Object?>{'blur': 10, 'contrast': 2, 'unknown': 9},
          ),
        ],
      },
      plugins: <MotionPathPlugin>[filterPlugin],
    );
    track.seek(0.5);
    final Map<String, Object?> filter =
        track.compose()['filter']! as Map<String, Object?>;
    expect(filter['blur'], 5.0);
    expect(filter['contrast'], 1.5);
    expect(filter.containsKey('unknown'), isFalse);
  });
}
