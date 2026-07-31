import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

Map<String, Object?> _stop(num p, Object? v) => <String, Object?>{
  'p': p,
  'v': v,
};

void main() {
  test('parses a valid MotionPath v4 project', () {
    final MotionPathProject project = MotionPathProject.fromJson(
      <String, Object?>{
        'schemaVersion': 4,
        'projectId': 'demo',
        'motions': <Object?>[
          <String, Object?>{
            'id': 'hero',
            'trigger': <String, Object?>{'type': 'manual'},
            'tracks': <Object?>[
              <String, Object?>{
                'id': 'hero-opacity',
                'duration': 1,
                'keyframes': <String, Object?>{
                  'opacity': <String, Object?>{
                    'stops': <Object?>[_stop(0, 0), _stop(1, 1)],
                  },
                },
              },
            ],
          },
        ],
      },
    );
    expect(project.schemaVersion, 4);
    expect(project.projectId, 'demo');
    expect(project.motions.single.id, 'hero');
    expect(project.motions.single.tracks.single.id, 'hero-opacity');
  });

  test('resolves track templates into authored tracks', () {
    final MotionPathProject project = MotionPathProject.fromJson(
      <String, Object?>{
        'schemaVersion': 4,
        'templates': <Object?>[
          <String, Object?>{
            'templateId': 'fade',
            'duration': 2,
            'keyframes': <String, Object?>{
              'opacity': <String, Object?>{
                'stops': <Object?>[_stop(0, 0), _stop(1, 1)],
              },
            },
          },
        ],
        'motions': <Object?>[
          <String, Object?>{
            'id': 'stamped',
            'trigger': <String, Object?>{'type': 'manual'},
            'tracks': <Object?>[
              <String, Object?>{'id': 'card', 'use': 'fade'},
            ],
          },
        ],
      },
    );
    final MotionPathTrack track = project.motions.single.tracks.single;
    expect(track.duration, 2);
    expect(track.keyframes.containsKey('opacity'), isTrue);
  });

  test('collects schema diagnostics before throwing', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(
      <String, Object?>{
        'schemaVersion': 3,
        'motions': <Object?>[
          <String, Object?>{'id': '', 'trigger': 'bad'},
        ],
      },
    );
    expect(
      diagnostics.map((MotionPathDiagnostic d) => d.code),
      containsAll(<String>[
        'schema-version',
        'motion-structure',
        'trigger-shape',
      ]),
    );
    expect(hasFatalErrors(diagnostics), isTrue);
  });

  test('rejects legacy v2 and v3 fields', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(
      <String, Object?>{
        'schemaVersion': 4,
        'motions': <Object?>[
          <String, Object?>{
            'motionId': 'legacy',
            'id': 'legacy',
            'driver': <String, Object?>{'type': 'time'},
            'playback': <String, Object?>{},
            'trigger': <String, Object?>{'type': 'time'},
            'tracks': <Object?>[
              <String, Object?>{
                'id': 'a',
                'keyframes': <String, Object?>{
                  'opacity': <String, Object?>{
                    'stops': <Object?>[_stop(0, 0), _stop(1, 1)],
                  },
                },
              },
            ],
          },
        ],
      },
    );
    final Iterable<String> paths = diagnostics.map(
      (MotionPathDiagnostic d) => d.path,
    );
    expect(paths, contains('motions[0].motionId'));
    expect(paths, contains('motions[0].driver'));
    expect(paths, contains('motions[0].playback'));
  });

  test('rejects malformed JSON shape', () {
    expect(
      () => MotionPathProject.fromJson(<String, Object?>{'schemaVersion': 4}),
      throwsA(isA<MotionPathValidationException>()),
    );
  });
}
