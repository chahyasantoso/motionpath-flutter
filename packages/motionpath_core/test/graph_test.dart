import 'package:test/test.dart';
import 'package:motionpath_core/motionpath_core.dart';

void main() {
  test('compiles a stable parent-before-child order', () {
    final motion = MotionPathMotion(
      id: 'walker',
      trigger: const <String, Object?>{'type': 'manual'},
      tracks: const <MotionPathTrack>[
        MotionPathTrack(id: 'child', observes: <Map<String, Object?>>[<String, Object?>{'source': 'root', 'target': 'parentWorld', 'role': 'input'}]),
        MotionPathTrack(id: 'root'),
      ],
    );
    final graph = normalizeObservationGraph(motion);
    expect(graph.isValid, isTrue);
    expect(graph.order, <String>['root', 'child']);
  });

  test('diagnoses cycles and missing sources', () {
    final motion = MotionPathMotion(
      id: 'bad',
      trigger: const <String, Object?>{'type': 'manual'},
      tracks: const <MotionPathTrack>[
        MotionPathTrack(id: 'a', observes: <Map<String, Object?>>[<String, Object?>{'source': 'b', 'target': 'x'}]),
        MotionPathTrack(id: 'b', observes: <Map<String, Object?>>[<String, Object?>{'source': 'a', 'target': 'x'}]),
        MotionPathTrack(id: 'c', observes: <Map<String, Object?>>[<String, Object?>{'source': 'missing', 'target': 'x'}]),
      ],
    );
    final graph = normalizeObservationGraph(motion);
    expect(graph.errors.map((error) => error.code), containsAll(<String>['cycle', 'missing-source']));
  });
}
