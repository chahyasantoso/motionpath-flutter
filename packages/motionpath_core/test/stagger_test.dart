import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('delays later tracks by authored stagger seconds', () {
    final MotionPathProject project = MotionPathProject(
      schemaVersion: 4,
      projectId: 'stagger',
      motions: <MotionPathMotion>[
        MotionPathMotion(
          id: 'm',
          stagger: 0.25,
          trigger: const <String, Object?>{'type': 'manual'},
          tracks: <MotionPathTrack>[
            MotionPathTrack(
              id: 'first',
              keyframes: <String, Object?>{
                'x': <String, Object?>{
                  'stops': <Object?>[
                    <String, Object?>{'p': 0, 'v': 0},
                    <String, Object?>{'p': 1, 'v': 100},
                  ],
                },
              },
            ),
            MotionPathTrack(
              id: 'second',
              keyframes: <String, Object?>{
                'x': <String, Object?>{
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
    final MotionPathMotionRuntime motion = engine.mountMotion('m');
    motion.seek(0.25);
    expect(motion.tracks[0].compose()['x'], closeTo(25, 1e-9));
    expect(motion.tracks[1].compose()['x'], closeTo(0, 1e-9));
    motion.seek(0.5);
    expect(motion.tracks[1].compose()['x'], closeTo(25, 1e-9));
  });
}
