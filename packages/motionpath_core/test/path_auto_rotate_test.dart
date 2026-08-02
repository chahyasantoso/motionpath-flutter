import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

double _n(Object? value) => (value! as num).toDouble();

Map<String, Object?> _projectJson(Map<String, Object?> pathKeyframe) =>
    <String, Object?>{
      'schemaVersion': 4,
      'projectId': 'auto-rotate',
      'motions': <Object?>[
        <String, Object?>{
          'id': 'scene',
          'trigger': <String, Object?>{'type': 'manual'},
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'subject',
              'keyframes': <String, Object?>{'path': pathKeyframe},
            },
          ],
        },
      ],
    };

MotionPathTrackRuntime _authored(Map<String, Object?> pathKeyframe) {
  final MotionPathProject project = MotionPathProject.fromJson(
    _projectJson(pathKeyframe),
  );
  final MotionPathTrack track = project.motions.single.tracks.single;
  return MotionPathTrackRuntime(
    track.id,
    properties: propertiesFromTrack(track),
  );
}

List<Object?> _ramp() => <Object?>[
  <String, Object?>{'p': 0, 'v': 0},
  <String, Object?>{'p': 1, 'v': 1},
];

void main() {
  test('a rightward path reports a zero heading', () {
    final MotionPathTrackRuntime track = _authored(<String, Object?>{
      'points': <Object?>[
        <String, Object?>{'x': 0, 'y': 0},
        <String, Object?>{'x': 20, 'y': 0},
      ],
      'autoRotate': true,
      'stops': _ramp(),
    });
    track.seek(0.5);
    expect(_n(track.compose()['rotation']), closeTo(0, 1e-6));
  });

  test('a downward path reports a quarter turn', () {
    final MotionPathTrackRuntime track = _authored(<String, Object?>{
      'points': <Object?>[
        <String, Object?>{'x': 0, 'y': 0},
        <String, Object?>{'x': 0, 'y': 20},
      ],
      'autoRotate': true,
      'stops': _ramp(),
    });
    track.seek(0.5);
    // Screen space: +y is down, so a downward heading is +90 degrees.
    expect(_n(track.compose()['rotation']), closeTo(90, 1e-6));
  });

  test('the heading turns with the curve', () {
    final MotionPathTrackRuntime track = _authored(<String, Object?>{
      'points': <Object?>[
        <String, Object?>{'x': 0, 'y': 0},
        <String, Object?>{'x': 100, 'y': 100, 'ctrlX': 100, 'ctrlY': 0},
      ],
      'autoRotate': true,
      'stops': _ramp(),
    });
    track.seek(0);
    final double start = _n(track.compose()['rotation']);
    track.seek(1);
    final double end = _n(track.compose()['rotation']);
    // The quadratic leaves horizontal and arrives vertical.
    expect(start, closeTo(0, 1e-6));
    expect(end, closeTo(90, 1e-6));
  });

  test('a path without autoRotate emits no rotation at all', () {
    final MotionPathTrackRuntime track = _authored(<String, Object?>{
      'points': <Object?>[
        <String, Object?>{'x': 0, 'y': 0},
        <String, Object?>{'x': 0, 'y': 20},
      ],
      'stops': _ramp(),
    });
    track.seek(0.5);
    final Map<String, Object?> patch = track.compose();
    expect(patch.containsKey('rotation'), isFalse);
    expect(_n(patch['y']), closeTo(10, 1e-6));
  });

  test('position is unchanged by the autoRotate payload shape', () {
    Map<String, Object?> at(bool autoRotate) {
      final MotionPathTrackRuntime track = _authored(<String, Object?>{
        'points': <Object?>[
          <String, Object?>{'x': 0, 'y': 0},
          <String, Object?>{'x': 40, 'y': 0},
        ],
        if (autoRotate) 'autoRotate': true,
        'stops': _ramp(),
      });
      track.seek(0.25);
      return track.compose();
    }

    expect(_n(at(true)['x']), closeTo(_n(at(false)['x']), 1e-9));
  });
}
