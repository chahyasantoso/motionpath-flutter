import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('resolves GSAP style ease names', () {
    expect(MotionPathEasing.resolve('none')(0.4), closeTo(0.4, 1e-12));
    expect(MotionPathEasing.resolve('power2.in')(0.5), closeTo(0.125, 1e-12));
    expect(MotionPathEasing.resolve('power2.out')(0.5), closeTo(0.875, 1e-12));
    expect(MotionPathEasing.resolve('power2.inOut')(0.5), closeTo(0.5, 1e-12));
  });

  test('a bare family name resolves to its out variant', () {
    expect(
      MotionPathEasing.resolve('power1')(0.25),
      closeTo(MotionPathEasing.resolve('power1.out')(0.25), 1e-12),
    );
  });

  test('unknown names fall back to linear', () {
    expect(
      MotionPathEasing.resolve('wobble.sideways')(0.3),
      closeTo(0.3, 1e-12),
    );
    expect(MotionPathEasing.resolve(null)(0.3), closeTo(0.3, 1e-12));
  });

  test('every family stays inside the unit interval', () {
    for (final String family in MotionPathEasing.families) {
      for (final String direction in <String>['in', 'out', 'inOut']) {
        final Easing ease = MotionPathEasing.resolve('$family.$direction');
        for (int step = 0; step <= 10; step++) {
          final double value = ease(step / 10);
          expect(value, inInclusiveRange(0, 1), reason: '$family.$direction');
        }
      }
    }
  });

  test('an authored per stop ease drives interpolation', () {
    final List<MotionPathStop> stops = stopsFromKeyframe(<String, Object?>{
      'stops': <Object?>[
        <String, Object?>{'p': 0, 'v': 0},
        <String, Object?>{'p': 1, 'v': 100, 'ease': 'power2.in'},
      ],
    });
    expect(interpolateStops(stops, 0.5), closeTo(12.5, 1e-9));
  });
}
