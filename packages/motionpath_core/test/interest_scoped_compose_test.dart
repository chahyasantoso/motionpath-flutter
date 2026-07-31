import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

MotionPathTrackRuntime _track(String id, String property) => MotionPathTrackRuntime(
      id,
      properties: <String, List<MotionPathStop>>{
        property: const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 100),
        ],
      },
    );

void main() {
  test('default composition preserves the complete graph', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'motion',
      tracks: <MotionPathTrackRuntime>[
        _track('a', 'x'),
        _track('b', 'y'),
      ],
    );
    final Map<String, Map<String, Object?>> patches = motion.composeGraph();
    expect(patches.keys, <String>['a', 'b']);
    expect(motion.patches.keys, <String>['a', 'b']);
  });

  test('filtered composition excludes unrelated top-level tracks', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'motion',
      tracks: <MotionPathTrackRuntime>[
        _track('a', 'x'),
        _track('b', 'y'),
      ],
    );
    motion.composeGraph();
    final Map<String, Map<String, Object?>> filtered =
        motion.composeGraph(only: <String>{'a'});
    expect(filtered.keys, <String>['a']);
    expect(filtered['a']!['x'], 0);
    expect(motion.patches.keys, <String>['a', 'b']);
  });

  test('filtered composition still resolves an uninterested input ancestor', () {
    final MotionPathTrackRuntime parent = _track('parent', 'x');
    final MotionPathTrackRuntime child = MotionPathTrackRuntime(
      'child',
      properties: <String, List<MotionPathStop>>{
        'boneLength': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 10),
          MotionPathStop(progress: 1, value: 10),
        ],
      },
    )..observe(parent, role: 'input', input: 'parentWorld');
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'motion',
      tracks: <MotionPathTrackRuntime>[parent, child],
    );
    motion.composeGraph();
    final Map<String, Map<String, Object?>> filtered =
        motion.composeGraph(only: <String>{'child'});
    expect(filtered.keys, <String>['child']);
    expect(filtered['child']!['x'], 10);
  });
}
