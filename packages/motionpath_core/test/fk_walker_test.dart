import 'dart:math' as math;

import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

import 'fixtures/walker_rig.dart';

const List<double> _samples = <double>[0, 0.13, 0.37, 0.5, 0.71, 0.94, 1];

double _n(Object? value) => (value! as num).toDouble();

double _span(Map<String, Object?> a, Map<String, Object?> b) {
  final double dx = _n(a['x']) - _n(b['x']);
  final double dy = _n(a['y']) - _n(b['y']);
  return math.sqrt(dx * dx + dy * dy);
}

void main() {
  group('forward kinematics math', () {
    test('rotates the local offset by the parent world rotation', () {
      final MotionPathWorldTransform world = composeWorld(
        const MotionPathWorldTransform(x: 10, y: 5, rotation: 90),
        const MotionPathWorldTransform(x: 10),
      );
      expect(world.x, closeTo(10, 1e-9));
      expect(world.y, closeTo(15, 1e-9));
      expect(world.rotation, closeTo(90, 1e-9));
    });

    test('folds bone data into a flat renderer patch', () {
      final Map<String, Object?> patch = applyForwardKinematics(<String, Object?>{
        'parentWorld': <String, Object?>{'x': 0, 'y': 0, 'rotation': 0},
        'boneLength': 20,
        'boneRotation': 30,
      });
      expect(_n(patch['x']), closeTo(20, 1e-9));
      expect(_n(patch['y']), closeTo(0, 1e-9));
      expect(_n(patch['rotation']), closeTo(30, 1e-9));
      expect(stripInternalPatchKeys(patch).keys, isNot(contains('parentWorld')));
      expect(stripInternalPatchKeys(patch).keys, isNot(contains('boneLength')));
    });

    test('leaves a track that authors no bone data untouched', () {
      final Map<String, Object?> authored = <String, Object?>{'x': 5, 'y': 6};
      expect(applyForwardKinematics(authored), same(authored));
    });
  });

  group('walker rig', () {
    late MotionPathMotionRuntime motion;

    setUp(() {
      final MotionPathProject project = MotionPathProject.fromJson(walkerProjectJson());
      final MotionPathEngine engine = MotionPathEngine()..loadProject(project);
      motion = engine.mountMotion('fk-walk-cycle');
    });

    Map<String, Map<String, Object?>> at(double p) {
      motion.seek(p);
      return motion.composeGraph();
    }

    test('parses fourteen tracks and compiles a parent-first order', () {
      expect(motion.tracks.length, 14);
      final List<String> order = motion.graph!.order;
      expect(order.first, 'pelvis');
      expect(order.indexOf('chest'), greaterThan(order.indexOf('spine')));
      expect(order.indexOf('leg-near-foot'), greaterThan(order.indexOf('leg-near-shin')));
      expect(motion.graph!.isValid, isTrue);
    });

    test('keeps every joint at its authored bone length through the gait', () {
      for (final double p in _samples) {
        final Map<String, Map<String, Object?>> patches = at(p);
        expect(_span(patches['pelvis']!, patches['chest']!), closeTo(kTorso, 1e-6));
        for (final String side in <String>['near', 'far']) {
          expect(_span(patches['pelvis']!, patches['leg-$side-shin']!), closeTo(kThigh, 1e-6));
          expect(_span(patches['leg-$side-shin']!, patches['leg-$side-foot']!), closeTo(kShin, 1e-6));
          expect(_span(patches['chest']!, patches['arm-$side-fore']!), closeTo(kUpperArm, 1e-6));
        }
      }
    });

    test('moves the head from an animated bone length alone', () {
      final List<double> necks = <double>[];
      for (final double p in _samples) {
        final Map<String, Map<String, Object?>> patches = at(p);
        necks.add(_span(patches['chest']!, patches['head']!));
      }
      final double longest = necks.reduce(math.max);
      final double shortest = necks.reduce(math.min);
      expect(longest - shortest, greaterThan(1));
      expect(shortest, greaterThan(kNeck - 4));
      expect(longest, lessThan(kNeck + 4));
    });

    test('bends the knee across the gait', () {
      final List<double> angles = <double>[];
      for (final double p in _samples) {
        angles.add(_n(at(p)['leg-near-shin']!['rotation']));
      }
      expect(angles.reduce(math.max) - angles.reduce(math.min), greaterThan(10));
    });

    test('drags the whole body with the pelvis', () {
      final Map<String, Map<String, Object?>> start = at(0);
      final double pelvisX = _n(start['pelvis']!['x']);
      final double footX = _n(start['leg-near-foot']!['x']);
      final Map<String, Map<String, Object?>> end = at(1);
      expect(_n(end['pelvis']!['x']), greaterThan(pelvisX));
      expect(_n(end['leg-near-foot']!['x']), greaterThan(footX));
    });

    test('never leaks internal bone keys to the renderer', () {
      final Map<String, Map<String, Object?>> patches = at(0.5);
      for (final Map<String, Object?> patch in patches.values) {
        expect(patch.keys, isNot(contains('parentWorld')));
        expect(patch.keys, isNot(contains('boneLength')));
        expect(patch.keys, isNot(contains('boneRotation')));
      }
    });
  });

  group('graph publisher', () {
    test('composes parents first but publishes only dirty tracks', () {
      final MotionPathTrackRuntime root = MotionPathTrackRuntime('root', properties: <String, List<MotionPathStop>>{
        'x': const <MotionPathStop>[MotionPathStop(progress: 0, value: 100), MotionPathStop(progress: 1, value: 100)],
      });
      final MotionPathTrackRuntime bone = MotionPathTrackRuntime('bone', properties: <String, List<MotionPathStop>>{
        'boneLength': const <MotionPathStop>[MotionPathStop(progress: 0, value: 10), MotionPathStop(progress: 1, value: 10)],
      });
      const ObservationGraph graph = ObservationGraph(
        nodes: <ObservationNode>[ObservationNode('root'), ObservationNode('bone')],
        edges: <ObservationEdge>[
          ObservationEdge(source: 'root', target: 'bone', role: 'input', inputKey: 'parentWorld'),
        ],
        order: <String>['root', 'bone'],
        errors: <MotionPathDiagnostic>[],
      );
      final MotionPathGraphPublisher publisher = MotionPathGraphPublisher(
        <String, MotionPathTrackRuntime>{'root': root, 'bone': bone},
        graph: graph,
      );
      publisher.markDirty('bone');
      final Map<String, Map<String, Object?>> published = publisher.flush(graph.order);
      expect(published.keys, <String>['bone']);
      expect(_n(published['bone']!['x']), closeTo(110, 1e-9));
      expect(publisher.flush(graph.order), isEmpty);
    });
  });
}
