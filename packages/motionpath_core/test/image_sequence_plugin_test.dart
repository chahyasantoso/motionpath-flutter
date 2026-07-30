import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('selects discrete image frames without loading them', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'sprite',
      properties: <String, List<MotionPathStop>>{
        'imageSequence': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: <Object?>['a.png', 'b.png', 'c.png']),
          MotionPathStop(progress: 1, value: <Object?>['a.png', 'b.png', 'c.png']),
        ],
      },
      plugins: <MotionPathPlugin>[imageSequencePlugin],
    );
    track.seek(0.75);
    expect(track.compose()['image'], 'c.png');
    expect(track.compose().containsKey('imageSequence'), isFalse);
  });
}
