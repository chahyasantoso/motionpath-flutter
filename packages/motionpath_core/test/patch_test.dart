import 'package:test/test.dart';
import 'package:motionpath_core/motionpath_core.dart';

void main() {
  test('keeps animated properties separate', () {
    final track = MotionPathTrackRuntime('box', properties: <String, List<MotionPathStop>>{
      'opacity': const <MotionPathStop>[MotionPathStop(progress: 0, value: 0), MotionPathStop(progress: 1, value: 1)],
      'x': const <MotionPathStop>[MotionPathStop(progress: 0, value: 0), MotionPathStop(progress: 1, value: 100)],
    });
    track.seek(0.5);
    expect(track.compose()['opacity'], 0.5);
    expect(track.compose()['x'], 50);
  });

  test('returns graph patches in compiled order', () {
    final root = MotionPathTrackRuntime('root', properties: <String, List<MotionPathStop>>{
      'x': const <MotionPathStop>[MotionPathStop(progress: 0, value: 0), MotionPathStop(progress: 1, value: 10)],
    });
    final child = MotionPathTrackRuntime('child', properties: <String, List<MotionPathStop>>{
      'y': const <MotionPathStop>[MotionPathStop(progress: 0, value: 0), MotionPathStop(progress: 1, value: 20)],
    });
    final motion = MotionPathMotionRuntime(tracks: <MotionPathTrackRuntime>[child, root], id: 'graph');
    motion.prepare(const ObservationGraph(nodes: <ObservationNode>[ObservationNode('root'), ObservationNode('child')], edges: <ObservationEdge>[ObservationEdge(source: 'root', target: 'child', role: 'input')], order: <String>['root', 'child'], errors: <MotionPathDiagnostic>[]));
    final patches = motion.composeGraph();
    expect(patches.keys, <String>['root', 'child']);
  });
}
