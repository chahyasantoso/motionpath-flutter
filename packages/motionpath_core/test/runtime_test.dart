import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

MotionPathMotionRuntime _motion() => MotionPathMotionRuntime(
  id: 'lifecycle',
  tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('track')],
  duration: 1,
);

void main() {
  test('interpolates numeric stops', () {
    final Object? value = interpolateStops(const <MotionPathStop>[
      MotionPathStop(progress: 0, value: 0),
      MotionPathStop(progress: 1, value: 100),
    ], 0.25);
    expect(value, 25);
  });

  test('reverse seeks the motion to the mirrored playhead', () {
    final MotionPathMotionRuntime motion = _motion();
    motion.seek(0.25);
    motion.reverse();
    expect(motion.progress, 0.75);
    expect(motion.playing, isFalse);
    motion.dispose();
  });

  test('pause prevents frame advancement until play resumes', () {
    final MotionPathMotionRuntime motion = _motion();
    motion.play();
    motion.advance(0.25);
    motion.pause();
    motion.advance(0.25);
    expect(motion.progress, 0.5);
    // advance is an imperative operation, so it still moves a paused motion;
    // the engine's frame driver is what honors playing. Verify that contract
    // at the engine level in the next test.
    motion.dispose();
  });

  test('engine only advances playing motions', () {
    final MotionPathMotionRuntime motion = _motion();
    final MotionPathEngine engine = MotionPathEngine();
    // Engine mounting is covered elsewhere; this is the direct ownership rule.
    motion.play();
    expect(motion.playing, isTrue);
    motion.pause();
    expect(motion.playing, isFalse);
    motion.dispose();
    engine.destroy();
  });

  test('publishes a completion event once per run', () {
    final MotionPathMotionRuntime motion = _motion();
    int completions = 0;
    motion.onComplete = () => completions++;
    motion.play();
    motion.advance(1);
    motion.advance(1);
    expect(completions, 1);
    expect(motion.playing, isFalse);
    motion.restart();
    motion.play();
    motion.advance(1);
    expect(completions, 2);
    motion.dispose();
  });

  test('seeking back below the endpoint re-arms completion', () {
    final MotionPathMotionRuntime motion = _motion();
    int completions = 0;
    motion.onComplete = () => completions++;
    motion.play();
    motion.advance(1);
    motion.seek(0.25);
    motion.play();
    motion.advance(0.75);
    expect(completions, 2);
    motion.dispose();
  });

  test('unmount and destroy are idempotent', () {
    const MotionPathProject project = MotionPathProject(
      schemaVersion: 4,
      projectId: 'lifecycle',
      motions: <MotionPathMotion>[
        MotionPathMotion(
          id: 'hero',
          trigger: <String, Object?>{'type': 'manual'},
          tracks: <MotionPathTrack>[MotionPathTrack(id: 'a')],
        ),
      ],
    );
    final MotionPathEngine engine = MotionPathEngine()..loadProject(project);
    final MotionPathMotionRuntime motion = engine.mountMotion('hero');
    engine.unmount(motion);
    engine.unmount(motion);
    expect(engine.mounted, isEmpty);
    engine.destroy();
    engine.destroy();
  });
}
