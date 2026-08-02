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

    final thigh = walkerBoneTrack('leg-near-thigh');
    thigh.seek(0);
    final start = (thigh.compose()['boneRotation']! as num).toDouble();
    thigh.seek(0.5);
    final middle = (thigh.compose()['boneRotation']! as num).toDouble();
    expect(start, closeTo(90, 1e-9));
    expect(middle, closeTo(90, 1e-9));
  });
}
