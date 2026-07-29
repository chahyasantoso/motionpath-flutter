import 'package:test/test.dart';
import 'package:motionpath_core/motionpath_core.dart';

void main() {
  test('interpolates numeric stops', () {
    final value = interpolateStops(const <MotionPathStop>[
      MotionPathStop(progress: 0, value: 0),
      MotionPathStop(progress: 1, value: 100),
    ], 0.25);
    expect(value, 25);
  });

  test('mounts, seeks, and destroys a motion', () {
    final project = MotionPathProject(
      schemaVersion: 4,
      projectId: 'runtime',
      motions: const <MotionPathMotion>[
        MotionPathMotion(id: 'hero', trigger: <String, Object?>{'type': 'manual'}, tracks: <MotionPathTrack>[MotionPathTrack(id: 'opacity')]),
      ],
    );
    final engine = MotionPathEngine()..loadProject(project);
    final motion = engine.mountMotion('hero');
    motion.seek(0.5);
    expect(motion.progress, 0.5);
    expect(motion.graph?.isValid, isTrue);
    engine.destroy();
    expect(engine.project, isNull);
  });
}
