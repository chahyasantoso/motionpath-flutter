import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('interpolates numeric stops', () {
    final Object? value = interpolateStops(const <MotionPathStop>[
      MotionPathStop(progress: 0, value: 0),
      MotionPathStop(progress: 1, value: 100),
    ], 0.25);
    expect(value, 25);
  });

  test('publishes a completion event once per run', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'complete',
      tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('track')],
      duration: 1,
    );
    int completions = 0;
    motion.onComplete = () => completions++;
    motion.play();
    motion.advance(0.5);
    motion.advance(0.5);
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
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'rearm',
      tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('track')],
      duration: 1,
    );
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

  test('mounts, ticks, and destroys a motion', () {
    const MotionPathProject project = MotionPathProject(
      schemaVersion: 4,
      projectId: 'runtime',
      motions: <MotionPathMotion>[
        MotionPathMotion(
          id: 'hero',
          trigger: <String, Object?>{'type': 'manual'},
          tracks: <MotionPathTrack>[
            MotionPathTrack(
              id: 'opacity',
              keyframes: <String, Object?>{
                'opacity': <String, Object?>{
                  'stops': <Object?>[
                    <String, Object?>{'p': 0, 'v': 0},
                    <String, Object?>{'p': 1, 'v': 100},
                  ],
                },
              },
            ),
          ],
        ),
      ],
    );
    final MotionPathEngine engine = MotionPathEngine()..loadProject(project);
    final MotionPathMotionRuntime motion = engine.mountMotion('hero')..play();
    engine.tick(0.5);
    expect(motion.progress, 0.5);
    expect(motion.tracks.single.compose()['opacity'], 50);
    engine.destroy();
    expect(engine.project, isNull);
    expect(engine.mounted, isEmpty);
  });

  test('autoplay is owned by the trigger, not the caller', () {
    const MotionPathProject project = MotionPathProject(
      schemaVersion: 4,
      projectId: 'autoplay',
      motions: <MotionPathMotion>[
        MotionPathMotion(
          id: 'auto',
          trigger: <String, Object?>{'type': 'time', 'autoplay': true},
          tracks: <MotionPathTrack>[MotionPathTrack(id: 'a')],
        ),
        MotionPathMotion(
          id: 'idle',
          trigger: <String, Object?>{'type': 'manual'},
          tracks: <MotionPathTrack>[MotionPathTrack(id: 'b')],
        ),
      ],
    );
    final MotionPathEngine engine = MotionPathEngine()..loadProject(project);
    expect(engine.mountMotion('auto').playing, isTrue);
    expect(engine.mountMotion('idle').playing, isFalse);
    engine.destroy();
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
