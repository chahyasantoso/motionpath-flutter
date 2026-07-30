import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

List<String> _codes(List<MotionPathDiagnostic> diagnostics) =>
    diagnostics.map((MotionPathDiagnostic d) => d.code).toList(growable: false);

void main() {
  test('rejects repeat, delay, and duration on a scroll-scrub trigger', () {
    final List<MotionPathDiagnostic> diagnostics =
        validateProject(<String, Object?>{
      'schemaVersion': 4,
      'motions': <Object?>[
        <String, Object?>{
          'id': 'scrubbed',
          'trigger': <String, Object?>{
            'type': 'scroll',
            'scrub': true,
            'repeat': 2,
            'delay': 1,
          },
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'a',
              'duration': 1,
              'keyframes': <String, Object?>{
                'opacity': <String, Object?>{
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
      _codes(diagnostics).where((String code) => code == 'trigger-shape'),
      hasLength(3),
    );
  });

  test('requires scrub on a scroll trigger', () {
    final List<MotionPathDiagnostic> diagnostics =
        validateProject(<String, Object?>{
      'schemaVersion': 4,
      'motions': <Object?>[
        <String, Object?>{
          'id': 'scrolled',
          'trigger': <String, Object?>{'type': 'scroll'},
          'tracks': <Object?>[
            <String, Object?>{'id': 'a'},
          ],
        },
      ],
    });
    expect(
      diagnostics.map((MotionPathDiagnostic d) => d.path),
      contains('motions[0].trigger.scrub'),
    );
  });

  test('reports stop count, shape, and sequence problems', () {
    final List<MotionPathDiagnostic> diagnostics =
        validateProject(<String, Object?>{
      'schemaVersion': 4,
      'motions': <Object?>[
        <String, Object?>{
          'id': 'stops',
          'trigger': <String, Object?>{'type': 'time'},
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'single',
              'keyframes': <String, Object?>{
                'opacity': <String, Object?>{
                  'stops': <Object?>[
                    <String, Object?>{'p': 0.5, 'v': 1},
                  ],
                },
              },
            },
            <String, Object?>{
              'id': 'backwards',
              'keyframes': <String, Object?>{
                'x': <String, Object?>{
                  'stops': <Object?>[
                    <String, Object?>{'p': 0, 'v': 0},
                    <String, Object?>{'p': 0.8, 'v': 5},
                    <String, Object?>{'p': 0.4, 'v': 9},
                    <String, Object?>{'p': 1},
                  ],
                },
              },
            },
          ],
        },
      ],
    });
    final List<String> codes = _codes(diagnostics);
    expect(codes, contains('stop-count'));
    expect(codes, contains('stop-shape'));
    expect(codes, contains('stop-sequence'));
    expect(
      diagnostics.any((MotionPathDiagnostic d) =>
          d.severity == MotionPathSeverity.warning),
      isTrue,
    );
  });

  test('a warning alone never blocks loading', () {
    final List<MotionPathDiagnostic> diagnostics =
        validateProject(<String, Object?>{
      'schemaVersion': 4,
      'motions': <Object?>[
        <String, Object?>{
          'id': 'warned',
          'trigger': <String, Object?>{'type': 'time'},
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'a',
              'keyframes': <String, Object?>{
                'opacity': <String, Object?>{
                  'stops': <Object?>[
                    <String, Object?>{'p': 0.2, 'v': 0},
                    <String, Object?>{'p': 0.9, 'v': 1},
                  ],
                },
              },
            },
          ],
        },
      ],
    });
    expect(diagnostics, isNotEmpty);
    expect(hasFatalErrors(diagnostics), isFalse);
  });
}
