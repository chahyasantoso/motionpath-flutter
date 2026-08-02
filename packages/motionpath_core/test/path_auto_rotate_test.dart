import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

double _n(Object? value) => (value! as num).toDouble();

Map<String, Object?> _projectJson(Map<String, Object?> pathKeyframe) =>
    <String, Object?>{
      'schemaVersion': 4,
      'projectId': 'path-contract',
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
  test('a center anchor emits percentage alignment', () {
    final MotionPathTrackRuntime track = _authored(<String, Object?>{
      'points': <Object?>[
        <String, Object?>{'x': 0, 'y': 0},
        <String, Object?>{'x': 20, 'y': 0},
      ],
      'anchor': 'center',
      'stops': _ramp(),
    });
    final Map<String, Object?> patch = track.compose();
    expect(patch['xPercent'], -50);
    expect(patch['yPercent'], -50);
  });

  test('none anchor emits no percentage alignment', () {
    final MotionPathTrackRuntime track = _authored(<String, Object?>{
      'points': <Object?>[
        <String, Object?>{'x': 0, 'y': 0},
        <String, Object?>{'x': 20, 'y': 0},
      ],
      'anchor': 'none',
      'stops': _ramp(),
    });
    expect(track.compose().containsKey('xPercent'), isFalse);
  });

  test('object anchor emits authored percentages', () {
    final MotionPathTrackRuntime track = _authored(<String, Object?>{
      'points': <Object?>[
        <String, Object?>{'x': 0, 'y': 0},
        <String, Object?>{'x': 20, 'y': 0},
      ],
      'anchor': <String, Object?>{'xPercent': 0, 'yPercent': -100},
      'stops': _ramp(),
    });
    final Map<String, Object?> patch = track.compose();
    expect(patch['xPercent'], 0);
    expect(patch['yPercent'], -100);
  });

  test('rejects an invalid anchor at project load', () {
    expect(
      () => MotionPathProject.fromJson(_projectJson(<String, Object?>{
        'points': <Object?>[
          <String, Object?>{'x': 0, 'y': 0},
          <String, Object?>{'x': 20, 'y': 0},
        ],
        'anchor': <String, Object?>{'xPercent': 0},
        'stops': _ramp(),
      })),
      throwsA(isA<MotionPathValidationException>()),
    );
  });
}
