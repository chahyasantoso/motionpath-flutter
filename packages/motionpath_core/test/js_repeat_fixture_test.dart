import 'dart:convert';
import 'dart:io';

import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

// Expected values are sourced from the versioned trigger fixture; no runtime
// semantics are encoded in this harness.
Map<String, Object?> _fixture() => jsonDecode(
      File('test/fixtures/motionpath_repeat_fixtures.json').readAsStringSync(),
    ) as Map<String, Object?>;

Map<String, Object?> _case(Map<String, Object?> cases, String name) =>
    cases[name]! as Map<String, Object?>;

double _number(Object? value) => (value! as num).toDouble();

MotionPathTrackRuntime _track(String id, double duration) =>
    MotionPathTrackRuntime(
      id,
      duration: duration,
      properties: <String, List<MotionPathStop>>{
        'x': <MotionPathStop>[
          const MotionPathStop(progress: 0, value: 0),
          const MotionPathStop(progress: 1, value: 1),
        ],
      },
    );

void main() {
  final Map<String, Object?> fixture = _fixture();
  final Map<String, Object?> cases = fixture['cases']! as Map<String, Object?>;
  final double tolerance = _number(fixture['tolerance']);

  test('delay, repeat, yoyo, repeatDelay, and completion match the fixture', () {
    final Map<String, Object?> expected = _case(cases, 'delayRepeatYoyo');
    final MotionPathTrigger trigger = MotionPathTrigger.fromJson(
      expected['trigger']! as Map<String, Object?>,
    );
    final List<Object?> samples = expected['samples']! as List<Object?>;
    for (final Object? raw in samples) {
      final Map<String, Object?> sample = raw! as Map<String, Object?>;
      final double elapsed = _number(sample['elapsed']);
      expect(trigger.progressAt(elapsed, 1), closeTo(_number(sample['progress']), tolerance), reason: 'progress at $elapsed');
      expect(trigger.isFinished(elapsed, 1), sample['finished'], reason: 'finished at $elapsed');
    }
  });

  test('stagger maps elapsed time across tracks with different durations', () {
    final Map<String, Object?> expected = _case(cases, 'staggeredTracks');
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'staggered',
      duration: _number(expected['duration']),
      stagger: _number(expected['stagger']),
      tracks: <MotionPathTrackRuntime>[
        _track('short', 1),
        _track('long', 2),
      ],
    );
    final List<Object?> samples = expected['samples']! as List<Object?>;
    for (final Object? raw in samples) {
      final Map<String, Object?> sample = raw! as Map<String, Object?>;
      final double elapsed = _number(sample['elapsed']);
      motion.seek(elapsed / _number(expected['duration']));
      final Map<String, Object?> tracks = sample['tracks']! as Map<String, Object?>;
      for (final MapEntry<String, Object?> entry in tracks.entries) {
        expect(motion.tracks.firstWhere((MotionPathTrackRuntime track) => track.id == entry.key).progress, closeTo(_number(entry.value), tolerance), reason: '${entry.key} at $elapsed');
      }
    }
    motion.dispose();
  });
}
