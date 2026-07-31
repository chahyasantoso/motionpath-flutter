import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('validation rejects non-finite authored numbers', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(<String, Object?>{
      'schemaVersion': 4,
      'perspective': double.infinity,
      'motions': <Object?>[
        <String, Object?>{
          'id': 'hero',
          'stagger': double.nan,
          'trigger': <String, Object?>{
            'type': 'time',
            'delay': double.infinity,
          },
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'track',
              'duration': double.negativeInfinity,
              'keyframes': <String, Object?>{
                'x': <String, Object?>{
                  'stops': <Object?>[
                    <String, Object?>{'p': double.nan, 'v': 0},
                    <String, Object?>{'p': 1, 'v': double.infinity},
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
          diagnostic.code == 'finite-number'),
      hasLength(6),
    );
  });

  test('composed nested patches are recursively immutable', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'track',
      properties: <String, List<MotionPathStop>>{
        'cssVariables': <MotionPathStop>[
          MotionPathStop(progress: 0, value: <String, Object?>{'--x': 1}),
          MotionPathStop(progress: 1, value: <String, Object?>{'--x': 2}),
        ],
      },
    );
    final Map<String, Object?> patch = track.compose();

    expect(() => patch['cssVariables'] = <String, Object?>{}, throwsUnsupportedError);
    final Object? nested = patch['cssVariables'];
    if (nested is Map<Object?, Object?>) {
      expect(() => nested['--x'] = 99, throwsUnsupportedError);
    }
  });

  test('immutablePatch freezes nested lists and maps', () {
    final Map<String, Object?> patch = immutablePatch(<String, Object?>{
      'instances': <Object?>[
        <String, Object?>{'x': 1},
      ],
    });
    final Object? instances = patch['instances'];
    expect(() => (instances as List<Object?>).add(<String, Object?>{}), throwsUnsupportedError);
    final Object? instance = instances.first;
    expect(() => (instance as Map<Object?, Object?>)['x'] = 2, throwsUnsupportedError);
  });
}
