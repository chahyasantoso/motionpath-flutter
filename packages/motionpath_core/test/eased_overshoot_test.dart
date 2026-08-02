import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

double _n(Object? value) => (value! as num).toDouble();

/// A single 0 -> 100 segment carrying [ease].
List<MotionPathStop> _segment(String ease) =>
    stopsFromKeyframe(<String, Object?>{
      'stops': <Object?>[
        <String, Object?>{'p': 0, 'v': 0},
        <String, Object?>{'p': 1, 'v': 100, 'ease': ease},
      ],
    });

void main() {
  group('eased overshoot reaches the value', () {
    test('back.out carries its overshoot past the authored target', () {
      final double eased = resolveEasing('back.out')(0.6);
      expect(eased, greaterThan(1));
      final double blended = _n(interpolateStops(_segment('back.out'), 0.6));
      expect(blended, greaterThan(100));
      expect(blended, closeTo(100 * eased, 1e-9));
    });

    test('elastic.out carries its overshoot past the authored target', () {
      final double eased = resolveEasing('elastic.out')(0.4);
      expect(eased, greaterThan(1));
      final double blended = _n(interpolateStops(_segment('elastic.out'), 0.4));
      expect(blended, greaterThan(100));
      expect(blended, closeTo(100 * eased, 1e-9));
    });

    test('back.in undershoots below the authored start', () {
      final double eased = resolveEasing('back.in')(0.3);
      expect(eased, lessThan(0));
      final double blended = _n(interpolateStops(_segment('back.in'), 0.3));
      expect(blended, lessThan(0));
      expect(blended, closeTo(100 * eased, 1e-9));
    });

    test('overshoot respects a non zero authored range', () {
      final List<MotionPathStop> stops = stopsFromKeyframe(<String, Object?>{
        'stops': <Object?>[
          <String, Object?>{'p': 0, 'v': 20},
          <String, Object?>{'p': 1, 'v': 60, 'ease': 'back.out'},
        ],
      });
      final double eased = resolveEasing('back.out')(0.6);
      expect(_n(interpolateStops(stops, 0.6)), closeTo(20 + 40 * eased, 1e-9));
      expect(_n(interpolateStops(stops, 0.6)), greaterThan(60));
    });

    test('authored endpoints stay pinned for every overshooting curve', () {
      const List<String> curves = <String>[
        'back.in',
        'back.out',
        'back.inOut',
        'elastic.in',
        'elastic.out',
        'elastic.inOut',
      ];
      for (final String ease in curves) {
        final List<MotionPathStop> stops = _segment(ease);
        expect(_n(interpolateStops(stops, 0)), closeTo(0, 1e-9), reason: ease);
        expect(_n(interpolateStops(stops, 1)), closeTo(100, 1e-9), reason: ease);
      }
    });

    test('playhead progress outside the authored range still clamps', () {
      final List<MotionPathStop> stops = _segment('back.out');
      expect(_n(interpolateStops(stops, -0.5)), closeTo(0, 1e-9));
      expect(_n(interpolateStops(stops, 1.5)), closeTo(100, 1e-9));
    });

    test('a composed track exposes the overshoot to subscribers', () {
      final MotionPathTrackRuntime runtime = MotionPathTrackRuntime(
        'chip',
        properties: <String, List<MotionPathStop>>{
          'x': _segment('back.out'),
        },
      );
      runtime.seek(0.6);
      expect(_n(runtime.compose()['x']), greaterThan(100));
      runtime.seek(1);
      expect(_n(runtime.compose()['x']), closeTo(100, 1e-9));
    });

    test('non overshooting curves are unchanged', () {
      expect(
        _n(interpolateStops(_segment('power2.in'), 0.5)),
        closeTo(12.5, 1e-9),
      );
      expect(_n(interpolateStops(_segment('none'), 0.5)), closeTo(50, 1e-9));
      expect(
        _n(interpolateStops(_segment('bounce.out'), 0.5)),
        lessThanOrEqualTo(100),
      );
    });
  });
}
