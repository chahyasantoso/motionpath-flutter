import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter_example/pasar_malam_scene.dart';

void main() {
  test('Pasar Malam ports the authored storytelling tracks', () {
    final List<MotionPathTrackRuntime> tracks = pasarMalamStoryTracks();
    expect(tracks, hasLength(8));
    expect(tracks.map((MotionPathTrackRuntime track) => track.id), containsAll(<String>[
      'pasar-malam-bg',
      'hero-title',
      'card-left',
      'card-right',
      'stats-card',
      'lantern-1-wrap',
      'lantern-2-wrap',
      'lantern-3-wrap',
    ]));
  });

  test('Pasar Malam preserves image-sequence frames and authored boundaries', () {
    expect(pasarMalamImageFrames, hasLength(pasarMalamFrameCount));
    expect(pasarMalamImageFrames.first, endsWith('frame_0001.webp'));
    expect(pasarMalamImageFrames.last, endsWith('frame_0192.webp'));

    final MotionPathTrackRuntime title = pasarMalamStoryTracks()[1];
    expect(title.compose()['opacity'], 0);
    title.seek(0.5);
    expect(title.compose()['opacity'], 1);
    title.seek(1);
    expect(title.compose()['opacity'], 0);
  });

  test('Pasar Malam preserves the three lantern bounce tracks and duration', () {
    final List<MotionPathTrackRuntime> tracks = pasarMalamBounceTracks();
    expect(tracks, hasLength(3));
    expect(tracks.every((MotionPathTrackRuntime track) => track.duration == pasarMalamBounceDuration), isTrue);
    expect(tracks.map((MotionPathTrackRuntime track) => track.id), containsAll(<String>[
      'lantern-1',
      'lantern-2',
      'lantern-3',
    ]));
  });
}
