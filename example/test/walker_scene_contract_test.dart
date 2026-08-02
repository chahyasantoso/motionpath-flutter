import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter_example/walker_scene.dart';

void main() {
  test('Walker project contains a real 14-track FK graph', () {
    final MotionPathProject project = walkerProject();
    final MotionPathMotion motion = project.motions.single;
    expect(motion.tracks, hasLength(14));
    expect(motion.tracks.first.id, 'pelvis');
    expect(motion.tracks.skip(1).map((track) => track.id), walkerBoneIds);
    expect(motion.tracks.skip(1).every((track) => track.observes.length == 1), isTrue);
  });

  test('Walker FK composes world patches from parent observations', () {
    final MotionPathEngine engine = MotionPathEngine()..loadProject(walkerProject());
    final MotionPathMotionRuntime motion = engine.mountMotion('fk-walk-cycle');
    motion.seek(0.5);
    final Map<String, Map<String, Object?>> patches = motion.composeGraph();
    expect(patches.keys, containsAll(<String>['pelvis', 'spine', 'head', 'leg-near-foot']));
    expect(patches['spine']!['x'], isA<num>());
    expect(patches['spine']!['y'], isA<num>());
    expect(patches['spine']!['rotation'], isA<num>());
    expect(patches['spine']!.containsKey('boneRotation'), isFalse);
    expect(patches['leg-near-foot']!['x'], isA<num>());
    engine.destroy();
  });

  test('Walker scene samples authored gait values at boundaries', () {
    expect(walkerBoneRotationAt('leg-near-thigh', 0), closeTo(90, 1e-9));
    expect(walkerBoneRotationAt('leg-near-thigh', 0.5), closeTo(90, 1e-9));
  });
}
