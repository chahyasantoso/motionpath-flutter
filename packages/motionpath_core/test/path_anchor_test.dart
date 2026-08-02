import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

Map<String, Object?> _project(Map<String, Object?> path) => <String, Object?>{
  'schemaVersion': 4,
  'motions': <Object?>[
    <String, Object?>{
      'id': 'scene',
      'trigger': <String, Object?>{'type': 'manual'},
      'tracks': <Object?>[
        <String, Object?>{'id': 'subject', 'keyframes': <String, Object?>{'path': path}},
      ],
    },
  ],
};

MotionPathTrackRuntime _track(Map<String, Object?> path) {
  final MotionPathProject project = MotionPathProject.fromJson(_project(path));
  final MotionPathTrack authored = project.motions.single.tracks.single;
  return MotionPathTrackRuntime(authored.id, properties: propertiesFromTrack(authored));
}

List<Object?> _stops() => <Object?>[
  <String, Object?>{'p': 0, 'v': 0},
  <String, Object?>{'p': 1, 'v': 1},
];

List<Object?> _points() => <Object?>[
  <String, Object?>{'x': 0, 'y': 0},
  <String, Object?>{'x': 20, 'y': 0},
];

void main() {
  test('center anchor emits percentage alignment', () {
    final Map<String, Object?> patch = _track(<String, Object?>{
      'points': _points(), 'anchor': 'center', 'stops': _stops(),
    }).compose();
    expect(patch['xPercent'], -50);
    expect(patch['yPercent'], -50);
  });

  test('none anchor emits no percentage alignment', () {
    final Map<String, Object?> patch = _track(<String, Object?>{
      'points': _points(), 'anchor': 'none', 'stops': _stops(),
    }).compose();
    expect(patch.containsKey('xPercent'), isFalse);
  });

  test('object anchor emits authored percentages', () {
    final Map<String, Object?> patch = _track(<String, Object?>{
      'points': _points(),
      'anchor': <String, Object?>{'xPercent': 0, 'yPercent': -100},
      'stops': _stops(),
    }).compose();
    expect(patch['xPercent'], 0);
    expect(patch['yPercent'], -100);
  });

  test('invalid anchor fails at project load', () {
    expect(
      () => MotionPathProject.fromJson(_project(<String, Object?>{
        'points': _points(),
        'anchor': <String, Object?>{'xPercent': 0},
        'stops': _stops(),
      })),
      throwsA(isA<MotionPathValidationException>()),
    );
  });
}
