import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

MotionPathMotion _motion(List<MotionPathTrack> tracks) => MotionPathMotion(
      id: 'graph',
      trigger: const <String, Object?>{'type': 'manual'},
      tracks: tracks,
    );

void main() {
  test('compiles a stable parent-before-child order', () {
    final ObservationGraph graph =
        normalizeObservationGraph(_motion(<MotionPathTrack>[
      const MotionPathTrack(
        id: 'child',
        observes: <Map<String, Object?>>[
          <String, Object?>{
            'source': 'root',
            'target': 'parentWorld',
            'role': 'input',
          },
        ],
      ),
      const MotionPathTrack(id: 'root'),
    ]));
    expect(graph.isValid, isTrue);
    expect(graph.order, <String>['root', 'child']);
    expect(graph.edges.single.input, 'parentWorld');
    expect(graph.edges.single.isInput, isTrue);
  });

  test('diagnoses cycles and missing sources', () {
    final ObservationGraph graph =
        normalizeObservationGraph(_motion(<MotionPathTrack>[
      const MotionPathTrack(
        id: 'a',
        observes: <Map<String, Object?>>[
          <String, Object?>{'source': 'b'},
        ],
      ),
      const MotionPathTrack(
        id: 'b',
        observes: <Map<String, Object?>>[
          <String, Object?>{'source': 'a'},
        ],
      ),
      const MotionPathTrack(
        id: 'c',
        observes: <Map<String, Object?>>[
          <String, Object?>{'source': 'missing'},
        ],
      ),
    ]));
    expect(
      graph.errors.map((MotionPathDiagnostic error) => error.code),
      containsAll(<String>[
        'track-observations',
        'track-observations-cycle',
      ]),
    );
    expect(graph.isValid, isFalse);
  });

  test('an input edge requires a target and an output edge forbids one', () {
    final ObservationGraph graph =
        normalizeObservationGraph(_motion(<MotionPathTrack>[
      const MotionPathTrack(id: 'root'),
      const MotionPathTrack(
        id: 'missing-target',
        observes: <Map<String, Object?>>[
          <String, Object?>{'source': 'root', 'role': 'input'},
        ],
      ),
      const MotionPathTrack(
        id: 'extra-target',
        observes: <Map<String, Object?>>[
          <String, Object?>{
            'source': 'root',
            'role': 'output',
            'target': 'nope',
          },
        ],
      ),
    ]));
    expect(graph.edges, isEmpty);
    expect(
      graph.errors.map((MotionPathDiagnostic error) => error.path),
      containsAll(<String>[
        'tracks[1].observes[0].target',
        'tracks[2].observes[0].target',
      ]),
    );
  });

  test('rejects duplicate nodes, self cycles, and duplicate edges', () {
    final ObservationGraph graph =
        normalizeObservationGraph(_motion(<MotionPathTrack>[
      const MotionPathTrack(id: 'root'),
      const MotionPathTrack(id: 'root'),
      const MotionPathTrack(
        id: 'self',
        observes: <Map<String, Object?>>[
          <String, Object?>{'source': 'self'},
        ],
      ),
      const MotionPathTrack(
        id: 'dupe',
        observes: <Map<String, Object?>>[
          <String, Object?>{'source': 'root'},
          <String, Object?>{'source': 'root'},
        ],
      ),
    ]));
    final Iterable<String> codes =
        graph.errors.map((MotionPathDiagnostic error) => error.code);
    expect(codes, contains('track-observations-duplicate-node'));
    expect(codes, contains('track-observations-cycle'));
    expect(codes, contains('track-observations-duplicate-edge'));
  });
}
