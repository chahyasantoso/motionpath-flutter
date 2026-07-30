import 'package:test/test.dart';
import 'package:motionpath_core/motionpath_core.dart';

void main() {
  test('keeps animated properties separate', () {
    final track = MotionPathTrackRuntime('box', properties: <String, List<MotionPathStop>>{
      'opacity': const <MotionPathStop>[MotionPathStop(progress: 0, value: 0), MotionPathStop(progress: 1, value: 1)],
      'x': const <MotionPathStop>[MotionPathStop(progress: 0, value: 0), MotionPathStop(progress: 1, value: 100)],
    });
    track.seek(0.5);
    expect(track.compose()['opacity'], 0.5);
    expect(track.compose()['x'], 50);
  });
}
