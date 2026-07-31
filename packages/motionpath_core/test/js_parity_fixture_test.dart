import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

Map<String, Object?> _fixture() =>
    jsonDecode(
          File(
            'test/fixtures/motionpath_parity_fixtures.json',
          ).readAsStringSync(),
        )
        as Map<String, Object?>;

double _number(Object? value) => (value! as num).toDouble();

String _progressKey(double progress) => progress == progress.roundToDouble()
    ? progress.toInt().toString()
    : progress.toString();

Map<String, Object?> _case(
  Map<String, Object?> cases,
  String name,
  double progress,
) {
  final Map<String, Object?> samples = cases[name]! as Map<String, Object?>;
  return samples[_progressKey(progress)]! as Map<String, Object?>;
}

void _expectNumber(Object? actual, Object? expected) {
  expect(_number(actual), closeTo(_number(expected), 1e-9));
}

/// Mirrors the JS reference project's power1.inOut easing, applied to the
/// *seek* progress itself for plugins (image sequence, path) whose
/// composition reads the track's raw progress rather than a per-stop
/// interpolated value.
double _easeInOutQuad(double t) =>
    t < 0.5 ? 2 * t * t : 1 - (math.pow(-2 * t + 2, 2)) / 2;

void main() {
  final Map<String, Object?> fixture = _fixture();
  final Map<String, Object?> cases = fixture['cases']! as Map<String, Object?>;

  test('JS easing samples match Flutter interpolation', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'easing',
      properties: <String, List<MotionPathStop>>{
        'x': <MotionPathStop>[
          const MotionPathStop(progress: 0, value: 0),
          MotionPathStop(
            progress: 1,
            value: 100,
            ease: resolveEasing('power2.in'),
          ),
        ],
      },
    );

    for (final double progress in <double>[0, 0.25, 0.5, 0.75, 1]) {
      track.seek(progress);
      _expectNumber(
        track.compose()['x'],
        (_case(cases, 'easing', progress)['easing']!
            as Map<String, Object?>)['x'],
      );
    }
  });

  test('JS transform and color samples match renderer-neutral values', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'render-contract',
      properties: <String, List<MotionPathStop>>{
        'x': <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(
            progress: 1,
            value: 100,
            ease: resolveEasing('power1.inOut'),
          ),
        ],
        'y': <MotionPathStop>[
          MotionPathStop(progress: 0, value: 40),
          MotionPathStop(
            progress: 1,
            value: -40,
            ease: resolveEasing('power1.inOut'),
          ),
        ],
        'rotation': <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(
            progress: 1,
            value: 90,
            ease: resolveEasing('power1.inOut'),
          ),
        ],
        'scale': <MotionPathStop>[
          MotionPathStop(progress: 0, value: 1),
          MotionPathStop(
            progress: 1,
            value: 2,
            ease: resolveEasing('power1.inOut'),
          ),
        ],
        'opacity': <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(
            progress: 1,
            value: 1,
            ease: resolveEasing('power1.inOut'),
          ),
        ],
        'color': <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0xFF000000),
          MotionPathStop(
            progress: 1,
            value: 0xFFFFFFFF,
            ease: resolveEasing('power1.inOut'),
          ),
        ],
      },
    );

    for (final double progress in <double>[0, 0.25, 0.5, 0.75, 1]) {
      track.seek(progress);
      final Map<String, Object?> actual = track.compose();
      final Map<String, Object?> expected =
          _case(cases, 'transformsAndColors', progress)['render-contract']!
              as Map<String, Object?>;
      for (final String key in <String>[
        'x',
        'y',
        'rotation',
        'scale',
        'opacity',
      ]) {
        _expectNumber(actual[key], expected[key]);
      }
      final String color = expected['color']! as String;
      final int expectedArgb = color == '#000000'
          ? 0xFF000000
          : color == '#ffffff'
          ? 0xFFFFFFFF
          : <String, int>{
              'rgba(32,32,32,1)': 0xFF202020,
              'rgba(128,128,128,1)': 0xFF808080,
              'rgba(223,223,223,1)': 0xFFDFDFDF,
            }[color]!;
      expect(actual['color'], expectedArgb);
    }
  });

  test('JS filter samples match the composed filter object', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'filters',
      properties: <String, List<MotionPathStop>>{
        'filter': <MotionPathStop>[
          const MotionPathStop(
            progress: 0,
            value: <String, Object?>{'blur': 0, 'brightness': 1},
          ),
          MotionPathStop(
            progress: 1,
            value: <String, Object?>{'blur': 8, 'brightness': 1.5},
            ease: resolveEasing('power1.inOut'),
          ),
        ],
      },
      plugins: <MotionPathPlugin>[filterPlugin],
    );
    for (final double progress in <double>[0, 0.25, 0.5, 0.75, 1]) {
      track.seek(progress);
      final Map<String, Object?> actual =
          track.compose()['filter']! as Map<String, Object?>;
      final Map<String, Object?> expected =
          ((_case(cases, 'filters', progress)['filters']!
                  as Map<String, Object?>)['filter']!)
              as Map<String, Object?>;
      for (final String key in <String>['blur', 'brightness']) {
        _expectNumber(actual[key], expected[key]);
      }
    }
  });

  test('JS image sequence samples select the same frames', () {
    final List<Object?> frames = <Object?>[
      'frame-0.png',
      'frame-1.png',
      'frame-2.png',
      'frame-3.png',
    ];
    final MotionPathTrackRuntime track = MotionPathTrackRuntime(
      'images',
      properties: <String, List<MotionPathStop>>{
        'imageSequence': <MotionPathStop>[
          MotionPathStop(progress: 0, value: frames),
          MotionPathStop(progress: 1, value: frames),
        ],
      },
      plugins: <MotionPathPlugin>[imageSequencePlugin],
    );
    // imageSequencePlugin reads the track's raw seek progress directly
    // (it is not a stop-interpolated/eased property like transforms or
    // filters), so the JS reference's power1.inOut easing must be applied
    // to the progress value passed into seek() itself, matching how the
    // JS driver would have fed an already-eased playhead into this plugin.
    for (final double progress in <double>[0, 0.25, 0.5, 0.75, 1]) {
      track.seek(_easeInOutQuad(progress));
      final String actual = track.compose()['image']! as String;
      final String expected =
          (((_case(cases, 'imageSequence', progress)['images']!
                      as Map<String, Object?>)['backgroundImage']!)
                  as String)
              .replaceFirst('url(', '')
              .replaceFirst(')', '');
      expect(actual, expected);
    }
  });

  test('JS observation graph samples preserve output composition', () {
    final MotionPathTrackRuntime source = MotionPathTrackRuntime(
      'source',
      properties: <String, List<MotionPathStop>>{
        'x': <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(
            progress: 1,
            value: 100,
            ease: resolveEasing('power1.inOut'),
          ),
        ],
      },
    );
    final MotionPathTrackRuntime consumer = MotionPathTrackRuntime(
      'consumer',
      properties: <String, List<MotionPathStop>>{
        'opacity': <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0.2),
          MotionPathStop(
            progress: 1,
            value: 1,
            ease: resolveEasing('power1.inOut'),
          ),
        ],
      },
    );
    consumer.observe(source);
    for (final double progress in <double>[0, 0.25, 0.5, 0.75, 1]) {
      source.seek(progress);
      consumer.seek(progress);
      final Map<String, Object?> actual = consumer.compose();
      final Map<String, Object?> expected =
          _case(cases, 'observationGraph', progress)['consumer']!
              as Map<String, Object?>;
      _expectNumber(actual['opacity'], expected['opacity']);
      _expectNumber(actual['x'], expected['x']);
    }
  });
}
