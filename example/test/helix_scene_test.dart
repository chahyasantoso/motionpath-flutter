import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter_example/helix_scene.dart';

void main() {
  test('shared Helix scene composes authored 3D trajectory values', () {
    final List<dynamic> tracks = helixSceneTracks();
    expect(tracks, hasLength(5));

    final Map<String, Object?> center = tracks[2].compose() as Map<String, Object?>;
    expect(center['x'], 0);
    expect(center['y'], 0);
    expect(center['z'], 0);
    expect(center['rotationY'], 0);
    expect(center['scale'], 1);
    expect(center['perspective'], helixPerspective);
  });

  test('Helix samples preserve authored depth crossings and scale falloff', () {
    final List<dynamic> tracks = helixSceneTracks();
    final List<double> depths = <double>[
      for (final dynamic track in tracks)
        (track.compose()['z'] as num).toDouble(),
    ];
    final List<double> scales = <double>[
      for (final dynamic track in tracks)
        (track.compose()['scale'] as num).toDouble(),
    ];

    expect(depths, <double>[-240, -120, 0, 120, 240]);
    expect(scales, <double>[0.72, 0.86, 1, 0.86, 0.72]);
  });
}
