import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

import 'support/fixture_support.dart';

double _number(Object? value) => (value! as num).toDouble();
Map<String, Object?> _case(Map<String, Object?> cases, String name) => cases[name]! as Map<String, Object?>;
Map<String, Object?> _ramp(num from, num to) => <String, Object?>{'stops': <Object?>[<String, Object?>{'p': 0, 'v': from}, <String, Object?>{'p': 1, 'v': to}]};
Map<String, Object?> _hold(num value) => _ramp(value, value);
Map<String, Object?> _rampTrack(String id, Map<String, Object?> keyframes, {List<Map<String, Object?>> observes = const <Map<String, Object?>>[]}) => <String, Object?>{'id': id, 'duration': 1, 'keyframes': keyframes, 'observes': observes};

MotionPathProject _project(String name) {
  final Map<String, Object?> input = <String, Object?>{'schemaVersion': 4, 'projectId': name, 'motions': <Object?>[<String, Object?>{'id': name, 'trigger': <String, Object?>{'type': 'manual'}, 'tracks': <Object?>[]}]};
  final List<Object?> tracks = (input['motions']! as List<Object?>).single is Map<String, Object?> ? (((input['motions']! as List<Object?>).single as Map<String, Object?>)['tracks']! as List<Object?>) : <Object?>[];
  switch (name) {
    case 'inputEdge':
      tracks.add(_rampTrack('source', <String, Object?>{'x': _hold(10), 'y': _hold(20), 'rotation': _hold(30)}));
      tracks.add(_rampTrack('consumer', <String, Object?>{'boneLength': _hold(5), 'boneRotation': _hold(15)}, observes: <Map<String, Object?>>[<String, Object?>{'source': 'source', 'role': 'input', 'target': 'parentWorld'}]));
    case 'outputMerge':
      tracks.add(_rampTrack('source', <String, Object?>{'x': _hold(7), 'opacity': _hold(0.4)}));
      tracks.add(_rampTrack('consumer', <String, Object?>{'x': _hold(2), 'opacity': _hold(0.8), 'y': _hold(3)}, observes: <Map<String, Object?>>[<String, Object?>{'source': 'source', 'role': 'output'}]));
    case 'diamond':
      tracks.add(_rampTrack('root', <String, Object?>{'x': _hold(10), 'y': _hold(0), 'rotation': _hold(0)}));
      for (final Map<String, Object?> branch in <Map<String, Object?>>[<String, Object?>{'id': 'left', 'length': 30, 'rotation': 0}, <String, Object?>{'id': 'right', 'length': 30, 'rotation': 90}]) {
        tracks.add(_rampTrack(branch['id']! as String, <String, Object?>{'boneLength': _hold(branch['length']! as num), 'boneRotation': _hold(branch['rotation']! as num)}, observes: <Map<String, Object?>>[<String, Object?>{'source': 'root', 'role': 'input', 'target': 'parentWorld'}]));
      }
    case 'stableOrder':
      tracks.add(_rampTrack('child', const <String, Object?>{}, observes: <Map<String, Object?>>[<String, Object?>{'source': 'root'}]));
      tracks.add(_rampTrack('sibling', const <String, Object?>{}, observes: <Map<String, Object?>>[<String, Object?>{'source': 'root'}]));
      tracks.add(_rampTrack('root', const <String, Object?>{}));
  }
  return MotionPathProject.fromJson(input);
}

MotionPathMotion _invalidMotion(String name) {
  if (name == 'cycle') {
    return MotionPathMotion(id: name, trigger: const <String, Object?>{'type': 'manual'}, tracks: <MotionPathTrack>[const MotionPathTrack(id: 'a', observes: <Map<String, Object?>>[<String, Object?>{'source': 'b'}]), const MotionPathTrack(id: 'b', observes: <Map<String, Object?>>[<String, Object?>{'source': 'a'}])]);
  }
  return const MotionPathMotion(id: 'missingSource', trigger: <String, Object?>{'type': 'manual'}, tracks: <MotionPathTrack>[MotionPathTrack(id: 'consumer', observes: <Map<String, Object?>>[<String, Object?>{'source': 'missing'}])]);
}

void main() {
  final Map<String, Object?> fixture = readFixture('motionpath_observation_fixtures.json');
  final Map<String, Object?> cases = fixture['cases']! as Map<String, Object?>;
  final double tolerance = _number(fixture['tolerance']);
  for (final String name in <String>['inputEdge', 'outputMerge', 'diamond', 'stableOrder']) {
    test('$name matches the observation fixture', () {
      final Map<String, Object?> expected = _case(cases, name);
      final MotionPathEngine engine = MotionPathEngine()..loadProject(_project(name));
      final MotionPathMotionRuntime motion = engine.mountMotion(name);
      motion.seek(0.5);
      expect(motion.graphOrder, expected['graphOrder']);
      final Map<String, Map<String, Object?>> actual = motion.composeGraph();
      final Object? expectedPatches = expected['patches'];
      if (expectedPatches is Map<String, Object?>) {
        for (final MapEntry<String, Object?> entry in expectedPatches.entries) {
          final Map<String, Object?> patch = entry.value! as Map<String, Object?>;
          expect(actual[entry.key]!.keys.toSet(), patch.keys.toSet());
          for (final MapEntry<String, Object?> value in patch.entries) expect(_number(actual[entry.key]![value.key]), closeTo(_number(value.value), tolerance));
        }
      }
      engine.destroy();
    });
  }
  for (final String name in <String>['cycle', 'missingSource']) {
    test('$name diagnostics match the observation fixture', () {
      final Map<String, Object?> expected = _case(cases, name);
      final ObservationGraph graph = normalizeObservationGraph(_invalidMotion(name));
      expect(graph.order, expected['graphOrder']);
      expect(graph.isValid, expected['fatal'] == false);
      expect(graph.errors.map((MotionPathDiagnostic error) => error.code), containsAll(expected['errorCodes']! as List<Object?>));
    });
  }
}
