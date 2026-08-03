import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

MotionPathTrackRuntime _path(Object authored) => MotionPathTrackRuntime(
      'path',
      properties: <String, List<MotionPathStop>>{
        'path': <MotionPathStop>[
          MotionPathStop(progress: 0, value: authored),
          MotionPathStop(progress: 1, value: authored),
        ],
      },
      plugins: <MotionPathPlugin>[pathPlugin],
    );

void main() {
  test('duplicate observation edges fail instead of silently stacking', () {
    final MotionPathTrackRuntime target = MotionPathTrackRuntime('target');
    final MotionPathTrackRuntime source = MotionPathTrackRuntime('source');

    target.observe(source);
    expect(() => target.observe(source), throwsA(isA<StateError>()));

    final MotionPathTrackRuntime inputTarget = MotionPathTrackRuntime('input-target');
    inputTarget.observe(source, role: 'input', input: 'x');
    expect(
      () => inputTarget.observe(source, role: 'input', input: 'x'),
      throwsA(isA<StateError>()),
    );
    expect(inputTarget.observations, hasLength(1));
  });

  test('distinct observation edges remain valid', () {
    final MotionPathTrackRuntime target = MotionPathTrackRuntime('target');
    final MotionPathTrackRuntime source = MotionPathTrackRuntime('source');
    final MotionPathTrackRuntime other = MotionPathTrackRuntime('other');

    target.observe(source);
    target.observe(other);
    target.observe(source, role: 'input', input: 'x');
    expect(target.observations, hasLength(3));
  });

  test('malformed anchors produce no unsafe cast or non-finite output', () {
    final MotionPathTrackRuntime track = _path(<String, Object?>{
      'points': <Object?>[
        <String, Object?>{'x': 0, 'y': 0},
        <String, Object?>{'x': 10, 'y': 0},
      ],
      'anchor': <String, Object?>{
        'xPercent': double.infinity,
        'yPercent': 'bad',
      },
    });
    track.seek(0.5);
    final Map<String, Object?> patch = track.compose();
    expect(patch['xPercent'], isNull);
    expect(patch['yPercent'], isNull);
    expect(patch.values.whereType<double>().every((double value) => value.isFinite), isTrue);
  });

  test('non-finite path nodes are ignored consistently', () {
    final MotionPathTrackRuntime track = _path(<Object?>[
      <String, Object?>{'x': 0, 'y': 0},
      <String, Object?>{'x': double.nan, 'y': 10},
    ]);
    track.seek(0.5);
    expect(track.compose(), isEmpty);
  });
}
