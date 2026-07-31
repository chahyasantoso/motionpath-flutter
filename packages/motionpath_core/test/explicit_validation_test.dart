import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('project validation rejects unknown keyframe easing', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(<String, Object?>{
      'schemaVersion': 4,
      'motions': <Object?>[
        <String, Object?>{
          'id': 'hero',
          'trigger': <String, Object?>{'type': 'time'},
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'track',
              'keyframes': <String, Object?>{
                'opacity': <String, Object?>{
                  'ease': 'wobble.sideways',
                  'stops': <Object?>[
                    <String, Object?>{'p': 0, 'v': 0},
                    <String, Object?>{'p': 1, 'v': 1},
                  ],
                },
              },
            },
          ],
        },
      ],
    });

    expect(
      diagnostics.where((MotionPathDiagnostic diagnostic) =>
          diagnostic.code == 'ease-shape'),
      hasLength(1),
    );
  });

  test('project validation rejects unknown per-stop easing', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(<String, Object?>{
      'schemaVersion': 4,
      'motions': <Object?>[
        <String, Object?>{
          'id': 'hero',
          'trigger': <String, Object?>{'type': 'time'},
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'track',
              'keyframes': <String, Object?>{
                'x': <String, Object?>{
                  'stops': <Object?>[
                    <String, Object?>{'p': 0, 'v': 0, 'ease': 'bad.ease'},
                    <String, Object?>{'p': 1, 'v': 1},
                  ],
                },
              },
            },
          ],
        },
      ],
    });

    expect(
      diagnostics.where((MotionPathDiagnostic diagnostic) =>
          diagnostic.code == 'ease-shape'),
      hasLength(1),
    );
  });

  test('direct trigger parsing rejects unknown types', () {
    expect(
      () => MotionPathTrigger.fromJson(<String, Object?>{'type': 'timeline'}),
      throwsA(isA<StateError>()),
    );
  });

  test('fromJson rejects a project with an unknown easing', () {
    expect(
      () => MotionPathProject.fromJson(<String, Object?>{
        'schemaVersion': 4,
        'motions': <Object?>[
          <String, Object?>{
            'id': 'hero',
            'trigger': <String, Object?>{'type': 'time'},
            'tracks': <Object?>[
              <String, Object?>{
                'id': 'track',
                'keyframes': <String, Object?>{
                  'x': <String, Object?>{
                    'ease': 'not-real',
                    'stops': <Object?>[
                      <String, Object?>{'p': 0, 'v': 0},
                      <String, Object?>{'p': 1, 'v': 1},
                    ],
                  },
                },
              },
            ],
          },
        ],
      }),
      throwsA(isA<MotionPathValidationException>()),
    );
  });
}
