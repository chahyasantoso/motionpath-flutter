import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/burst_scene.dart';

void main() {
  test('Burst ports all eleven JS cards and perspective', () {
    final tracks = burstSceneTracks();
    expect(tracks, hasLength(11));
    expect(tracks.first.id, 'strawberry-1');
    expect(tracks.last.id, 'ice-cream-center');
    expect(tracks.last.compose()['perspective'], burstPerspective);
  });

  test('Burst cards start invisible and end on authored opacity boundary', () {
    final track = burstCardTrack(burstCards.first);
    expect(track.compose()['opacity'], 0);
    track.seek(1);
    expect(track.compose()['opacity'], 0);
  });
}
