import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/motorcycle_scene.dart';

void main() {
  test('Motorcycle ports road, shadow, cloud, and streak tracks', () {
    final tracks = motorcycleSceneTracks();
    expect(tracks, hasLength(6));
    expect(tracks.map((track) => track.id), containsAll(<String>[
      'moto-bike', 'moto-shadow', 'moto-cloud-a', 'moto-cloud-b',
      'moto-streak-a', 'moto-streak-b',
    ]));
  });

  test('Motorcycle keeps the main ride duration and authored path payload', () {
    final track = motorcycleSceneTracks().first;
    expect(track.duration, motorcycleRideDuration);
    track.seek(0.5);
    expect(track.compose()['path'], isA<Map<Object?, Object?>>());
    expect(track.compose()['opacity'], isNotNull);
  });
}
