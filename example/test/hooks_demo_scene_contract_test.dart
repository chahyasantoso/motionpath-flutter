import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter_example/hooks_demo_scene.dart';

void main() {
  test('Hooks Demo ports the rocket and cloud tracks', () {
    final tracks = hooksDemoSceneTracks();
    expect(tracks, hasLength(2));
    expect(tracks.map((MotionPathTrackRuntime track) => track.id), containsAll(<String>['rocket-track', 'cloud']));
  });

  test('Hooks Demo composes authored path outputs and rocket styling', () {
    final rocket = hooksDemoSceneTracks().first;
    rocket.seek(0.5);
    final patch = rocket.compose();
    expect(patch['x'], isA<num>());
    expect(patch['y'], isA<num>());
    expect(patch['rotation'], isA<num>());
    expect(patch['scale'], closeTo(1.05, 0.001));
    expect(patch['opacity'], closeTo(0.7, 0.001));
  });
}
