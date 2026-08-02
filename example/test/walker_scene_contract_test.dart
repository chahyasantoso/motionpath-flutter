import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/walker_scene.dart';

void main() {
  test('Walker scene exposes one pelvis and thirteen authored bone tracks', () {
    final tracks = walkerSceneTracks();
    expect(tracks, hasLength(14));
    expect(tracks.first.id, 'pelvis');
    expect(tracks.skip(1).map((track) => track.id), walkerBoneIds);
  });

  test('Walker scene samples authored gait values at boundaries', () {
    final pelvis = walkerPelvisTrack();
    expect(pelvis.compose()['x'], walkerStartX);
    pelvis.seek(1);
    expect(pelvis.compose()['x'], walkerEndX);

    expect(walkerBoneRotationAt('leg-near-thigh', 0), closeTo(90, 1e-9));
    expect(walkerBoneRotationAt('leg-near-thigh', 0.5), closeTo(90, 1e-9));
  });
}
