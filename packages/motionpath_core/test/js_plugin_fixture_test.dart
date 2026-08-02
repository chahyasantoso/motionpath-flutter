import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

import 'support/fixture_support.dart';

Map<String, Object?> _case(Map<String, Object?> cases, String name) =>
    cases[name]! as Map<String, Object?>;

double _number(Object? value) => (value! as num).toDouble();

List<MotionPathStop> _stops(Map<String, Object?> pluginCase) => <MotionPathStop>[
      for (final Object? raw in pluginCase['stops']! as List<Object?>)
        MotionPathStop(
          progress: _number((raw! as Map<String, Object?>)['p']),
          value: (raw as Map<String, Object?>)['v'],
        ),
    ];

List<Map<String, Object?>> _samples(Map<String, Object?> pluginCase) =>
    <Map<String, Object?>>[
      for (final Object? raw in pluginCase['samples']! as List<Object?>)
        raw! as Map<String, Object?>,
    ];

void _expectNumericMap(
  Map<String, Object?> actual,
  Map<String, Object?> expected,
  double tolerance,
) {
  expect(actual.keys.toSet(), expected.keys.toSet());
  for (final MapEntry<String, Object?> entry in expected.entries) {
    expect(
      _number(actual[entry.key]),
      closeTo(_number(entry.value), tolerance),
      reason: entry.key,
    );
  }
}

void main() {
  final Map<String, Object?> fixture =
      readFixture('motionpath_plugin_fixtures.json');
  final Map<String, Object?> cases = fixture['cases']! as Map<String, Object?>;
  final double tolerance = _number(fixture['tolerance']);

  test('filter plugin matches fixture samples and drops unknown keys', () {
    final Map<String, Object?> pluginCase = _case(cases, 'filter');
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'filters',
      properties: <String, List<MotionPathStop>>{
        'filter': _stops(pluginCase),
      },
      plugins: <MotionPathPlugin>[filterPlugin],
    );
    for (final Map<String, Object?> sample in _samples(pluginCase)) {
      final double progress = _number(sample['progress']);
      track.seek(progress);
      final Map<String, Object?> actual =
          track.compose()['filter']! as Map<String, Object?>;
      final Map<String, Object?> expected =
          (sample['patch']! as Map<String, Object?>)['filter']!
              as Map<String, Object?>;
      _expectNumericMap(actual, expected, tolerance);
    }
  });

  test('CSS variable plugin keeps custom properties and drops invalid keys', () {
    final Map<String, Object?> pluginCase = _case(cases, 'cssVariables');
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'styles',
      properties: <String, List<MotionPathStop>>{
        'cssVariables': _stops(pluginCase),
      },
      plugins: <MotionPathPlugin>[cssVariablePlugin],
    );
    for (final Map<String, Object?> sample in _samples(pluginCase)) {
      final double progress = _number(sample['progress']);
      track.seek(progress);
      final Map<String, Object?> actual =
          track.compose()['cssVariables']! as Map<String, Object?>;
      final Map<String, Object?> expected =
          (sample['patch']! as Map<String, Object?>)['cssVariables']!
              as Map<String, Object?>;
      _expectNumericMap(actual, expected, tolerance);
    }
  });
}
