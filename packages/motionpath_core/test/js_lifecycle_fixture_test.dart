import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

import 'support/fixture_support.dart';

Map<String, Object?> _case(Map<String, Object?> cases, String name) =>
    cases[name]! as Map<String, Object?>;

Map<String, Object?> _project({
  String id = 'lifecycle',
  Map<String, Object?> trigger = const <String, Object?>{
    'type': 'time',
  },
}) => <String, Object?>{
  'schemaVersion': 4,
  'projectId': id,
  'motions': <Object?>[
    <String, Object?>{
      'id': id,
      'trigger': trigger,
      'tracks': <Object?>[
        <String, Object?>{
          'id': 'track',
          'duration': 1,
          'keyframes': <String, Object?>{
            'x': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': 0},
                <String, Object?>{'p': 1, 'v': 100},
              ],
            },
          },
        },
      ],
    },
  ],
};

void main() {
  final Map<String, Object?> fixture =
      readFixture('motionpath_lifecycle_fixtures.json');
  final Map<String, Object?> cases = fixture['cases']! as Map<String, Object?>;

  test('mount and prepare lifecycle matches the fixture', () {
    final Map<String, Object?> expected = _case(cases, 'mountPrepare');
    final MotionPathEngine engine = MotionPathEngine();
    expect(engine.mounted, hasLength(expected['mountedBefore']));
    engine.loadProject(MotionPathProject.fromJson(_project()));
    final MotionPathMotionRuntime motion = engine.mountMotion('lifecycle');
    expect(engine.mounted, hasLength(expected['mountedAfter']));
    expect(motion.playing, expected['autoplay']);
    expect(motion.graph, isNotNull);
    expect(() => engine.mountMotion('lifecycle'), throwsStateError);
    expect(
      () => motion.prepare(normalizeObservationGraph(
        MotionPathProject.fromJson(_project()).motions.single,
      )),
      throwsStateError,
    );
    engine.destroy();
  });

  test('play, pause, seek, and reverse preserve the lifecycle matrix', () {
    final Map<String, Object?> expected = _case(
      cases,
      'playPauseSeekReverse',
    );
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'lifecycle',
      tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('track')],
      duration: 1,
    );
    motion.play();
    expect(motion.playing, (expected['afterPlay']! as Map<String, Object?>)['playing']);
    motion.advance(0.25);
    final Map<String, Object?> afterAdvance = expected['afterAdvance']! as Map<String, Object?>;
    expect(motion.progress, afterAdvance['progress']);
    expect(motion.tracks.single.progress, afterAdvance['trackProgress']);
    motion.pause();
    expect(motion.playing, (expected['afterPause']! as Map<String, Object?>)['playing']);
    motion.seek(0.75);
    final Map<String, Object?> afterSeek = expected['afterSeek']! as Map<String, Object?>;
    expect(motion.progress, afterSeek['progress']);
    expect(motion.tracks.single.progress, afterSeek['trackProgress']);
    motion.reverse();
    final Map<String, Object?> afterReverse = expected['afterReverse']! as Map<String, Object?>;
    expect(motion.progress, afterReverse['progress']);
    expect(motion.tracks.single.progress, afterReverse['trackProgress']);
    motion.dispose();
  });

  test('completion is one-shot and re-arms after restart', () {
    final Map<String, Object?> expected = _case(cases, 'completionRestart');
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'lifecycle',
      tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('track')],
      duration: 1,
    );
    int completions = 0;
    motion.onComplete = () => completions++;
    motion.play();
    motion.advance(1);
    expect(completions, expected['completionAfterFirstAdvance']);
    expect(motion.playing, expected['playingAtCompletion']);
    motion.advance(1);
    expect(completions, expected['completionAfterSecondAdvance']);
    motion.restart();
    motion.play();
    motion.advance(1);
    expect(completions, expected['completionAfterRestart']);
    motion.dispose();
  });

  test('unmount and destroy are idempotent', () {
    final Map<String, Object?> expected = _case(cases, 'unmountDestroy');
    final MotionPathEngine engine = MotionPathEngine()
      ..loadProject(MotionPathProject.fromJson(_project()));
    final MotionPathMotionRuntime motion = engine.mountMotion('lifecycle');
    engine.unmount(motion);
    expect(engine.mounted, hasLength(expected['mountedAfterFirstUnmount']));
    engine.unmount(motion);
    expect(engine.mounted, hasLength(expected['mountedAfterSecondUnmount']));
    engine.destroy();
    expect(engine.mounted, hasLength(expected['mountedAfterFirstDestroy']));
    engine.destroy();
    expect(engine.mounted, hasLength(expected['mountedAfterSecondDestroy']));
    expect(engine.project, expected['projectAfterDestroy']);
  });
}
