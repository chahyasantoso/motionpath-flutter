import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('keeps animated properties separate', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'box',
      properties: <String, List<MotionPathStop>>{
        'opacity': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 1),
        ],
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 100),
        ],
      },
    );
    track.seek(0.5);
    expect(track.compose()['opacity'], 0.5);
    expect(track.compose()['x'], 50);
  });

  test('returns graph patches in compiled order', () {
    final MotionPathTrackRuntime root = MotionPathTrackRuntime(
      'root',
      properties: <String, List<MotionPathStop>>{
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 10),
        ],
      },
    );
    final MotionPathTrackRuntime child = MotionPathTrackRuntime(
      'child',
      properties: <String, List<MotionPathStop>>{
        'y': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 20),
        ],
      },
    );
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'graph',
      tracks: <MotionPathTrackRuntime>[child, root],
    );
    motion.prepare(
      const ObservationGraph(
        nodes: <ObservationNode>[
          ObservationNode('root'),
          ObservationNode('child', index: 1),
        ],
        edges: <ObservationEdge>[
          ObservationEdge(
            source: 'root',
            target: 'child',
            role: 'input',
            input: 'parentWorld',
          ),
        ],
        order: <String>['root', 'child'],
        errors: <MotionPathDiagnostic>[],
      ),
    );
    final Map<String, Map<String, Object?>> patches = motion.composeGraph();
    expect(patches.keys, <String>['root', 'child']);
    expect(motion.graphOrder, <String>['root', 'child']);
  });

  test('an output observation merges over the observing patch', () {
    final MotionPathTrackRuntime overlay = MotionPathTrackRuntime(
      'overlay',
      properties: <String, List<MotionPathStop>>{
        'opacity': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 1),
          MotionPathStop(progress: 1, value: 1),
        ],
      },
    );
    final MotionPathTrackRuntime base = MotionPathTrackRuntime(
      'base',
      properties: <String, List<MotionPathStop>>{
        'opacity': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 0),
        ],
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 4),
          MotionPathStop(progress: 1, value: 4),
        ],
      },
    )..observe(overlay);
    final Map<String, Object?> patch = base.compose();
    expect(patch['opacity'], 1);
    expect(patch['x'], 4);
  });

  test('internal plugin keys never reach a patch', () {
    final MotionPathTrackRuntime bone = MotionPathTrackRuntime(
      'bone',
      properties: <String, List<MotionPathStop>>{
        'boneLength': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 10),
          MotionPathStop(progress: 1, value: 10),
        ],
        'boneRotation': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 0),
        ],
      },
    );
    final Map<String, Object?> patch = bone.compose();
    expect(patch.containsKey('boneLength'), isFalse);
    expect(patch.containsKey('boneRotation'), isFalse);
    expect(patch['x'], 10);
    expect(patch['y'], 0);
  });
}
