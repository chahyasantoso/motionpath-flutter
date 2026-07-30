import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

/// Families that deliberately leave the unit interval, like the reference.
const List<String> _overshooting = <String>['back', 'elastic'];

void main() {
  test('resolves GSAP style ease names', () {
    expect(resolveEasing('none')(0.4), closeTo(0.4, 1e-12));
    expect(resolveEasing('power2.in')(0.5), closeTo(0.125, 1e-12));
    expect(resolveEasing('power2.out')(0.5), closeTo(0.875, 1e-12));
    expect(resolveEasing('power2.inOut')(0.5), closeTo(0.5, 1e-12));
  });

  test('a bare family name resolves to its out variant', () {
    expect(
      resolveEasing('power1')(0.25),
      closeTo(resolveEasing('power1.out')(0.25), 1e-12),
    );
  });

  test('unknown names fall back to linear', () {
    expect(resolveEasing('wobble.sideways')(0.3), closeTo(0.3, 1e-12));
    expect(resolveEasing(null)(0.3), closeTo(0.3, 1e-12));
  });

  test('every non-overshooting curve stays inside the unit interval', () {
    for (final String name in motionPathEasingNames) {
      if (_overshooting.any(name.startsWith)) {
        continue;
      }
      final Easing ease = resolveEasing(name);
      for (int step = 0; step <= 10; step++) {
        expect(ease(step / 10), inInclusiveRange(0, 1), reason: name);
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
