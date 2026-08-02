import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

double _n(Object? value) => (value! as num).toDouble();

Map<String, Object?> _projectJson(Map<String, Object?> keyframes) =>
    <String, Object?>{
      'schemaVersion': 4,
      'projectId': 'authored-payload',
      'motions': <Object?>[
        <String, Object?>{
          'id': 'scene',
          'trigger': <String, Object?>{'type': 'manual'},
          'tracks': <Object?>[
            <String, Object?>{'id': 'subject', 'keyframes': keyframes},
          ],
        },
      ],
    };

/// Builds a runtime the way a host does: authored JSON, then the shared
/// property conversion. Passing stops in by hand would skip the boundary this
/// regression lives on.
MotionPathTrackRuntime _authored(Map<String, Object?> keyframes) {
  final MotionPathProject project = MotionPathProject.fromJson(
    _projectJson(keyframes),
  );
  final MotionPathTrack track = project.motions.single.tracks.single;
  return MotionPathTrackRuntime(
    track.id,
    properties: propertiesFromTrack(track),
  );
}

const Map<String, Object?> _straightPath = <String, Object?>{
  'path': <String, Object?>{
    'points': <Object?>[
      <String, Object?>{'x': 0, 'y': 0},
      <String, Object?>{'x': 20, 'y': 0},
    ],
    'stops': <Object?>[
      <String, Object?>{'p': 0, 'v': 0},
      <String, Object?>{'p': 1, 'v': 1},
    ],
  },
};

void main() {
  group('authored path geometry', () {
    test('composes a sampled position instead of raw geometry', () {
      final MotionPathTrackRuntime track = _authored(_straightPath);
      track.seek(0.5);
      final Map<String, Object?> patch = track.compose();
      expect(_n(patch['x']), closeTo(10, 1e-6));
      expect(_n(patch['y']), closeTo(0, 1e-6));
      // Geometry is internal. A renderer only ever sees the sample.
      expect(patch.containsKey('path'), isFalse);
    });

    test('tracks the playhead across the whole path', () {
      final MotionPathTrackRuntime track = _authored(_straightPath);
      track.seek(0);
      expect(_n(track.compose()['x']), closeTo(0, 1e-6));
      track.seek(1);
      expect(_n(track.compose()['x']), closeTo(20, 1e-6));
    });

    test('resolves the path plugin from the default registry', () {
      final MotionPathTrackRuntime track = _authored(_straightPath);
      expect(
        track.plugins.map((MotionPathPlugin plugin) => plugin.name),
        contains('path'),
      );
    });
  });

  group('authored image sequences', () {
    test('selects the frame at the playhead', () {
      final MotionPathTrackRuntime track = _authored(<String, Object?>{
        'imageSequence': <String, Object?>{
          'frames': <Object?>['a.webp', 'b.webp', 'c.webp'],
          'stops': <Object?>[
            <String, Object?>{'p': 0, 'v': 0},
            <String, Object?>{'p': 1, 'v': 2},
          ],
        },
      });
      track.seek(0);
      expect(track.compose()['image'], 'a.webp');
      track.seek(1);
      expect(track.compose()['image'], 'c.webp');
    });
  });

  group('malformed payloads', () {
    test('a path keyframe without points fails loudly', () {
      expect(
        () => stopsFromKeyframe(<String, Object?>{
          'stops': <Object?>[
            <String, Object?>{'p': 0, 'v': 0},
            <String, Object?>{'p': 1, 'v': 1},
          ],
        }, propertyKey: 'path'),
        throwsArgumentError,
      );
    });

    test('an empty frame list fails loudly', () {
      expect(
        () => stopsFromKeyframe(<String, Object?>{
          'frames': <Object?>[],
          'stops': <Object?>[
            <String, Object?>{'p': 0, 'v': 0},
            <String, Object?>{'p': 1, 'v': 1},
          ],
        }, propertyKey: 'imageSequence'),
        throwsArgumentError,
      );
    });

    test('leaves ordinary properties on the interpolated path', () {
      final List<MotionPathStop> stops = stopsFromKeyframe(<String, Object?>{
        'stops': <Object?>[
          <String, Object?>{'p': 0, 'v': 0},
          <String, Object?>{'p': 1, 'v': 100},
        ],
      }, propertyKey: 'opacity');
      expect(_n(interpolateStops(stops, 0.5)), closeTo(50, 1e-9));
    });
  });
}
