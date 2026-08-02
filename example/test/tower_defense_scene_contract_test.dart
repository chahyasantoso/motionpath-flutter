import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter_example/tower_defense_scene.dart';

void main() {
  test('Tower Defense ports both authored lanes and interaction tracks', () {
    final tracks = towerDefenseSceneTracks();
    expect(tracks, hasLength(5));
    expect(tracks.map((MotionPathTrackRuntime track) => track.id), containsAll(<String>[
      'lane-1-track', 'lane-2-track', 'tower-pulse-ring', 'projectile-track', 'death-track',
    ]));
  });

  test('Tower Defense preserves path tangent and lifecycle boundaries', () {
    final track = towerDefensePathTrack('sample', towerDefenseLane1Points);
    track.seek(0.5);
    expect(track.compose()['x'], isA<num>());
    expect(track.compose()['y'], isA<num>());
    expect(track.compose()['rotation'], isA<num>());
    final death = towerDefenseSceneTracks().last;
    expect(death.compose()['opacity'], 1);
    death.seek(1);
    expect(death.compose()['opacity'], 0);
  });
}
