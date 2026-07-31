import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

double _n(Object? value) => (value! as num).toDouble();

void main() {
  group('easing registry', () {
    test('treats none and linear as the identity curve', () {
      expect(resolveEasing('none')(0.25), closeTo(0.25, 1e-9));
      expect(resolveEasing('linear')(0.75), closeTo(0.75, 1e-9));
      expect(resolveEasing(null)(0.4), closeTo(0.4, 1e-9));
    });

    test('ports the power families', () {
      expect(resolveEasing('power1.in')(0.5), closeTo(0.25, 1e-9));
      expect(resolveEasing('power1.out')(0.5), closeTo(0.75, 1e-9));
      expect(resolveEasing('power1.inOut')(0.5), closeTo(0.5, 1e-9));
      expect(resolveEasing('power2.in')(0.5), closeTo(0.125, 1e-9));
      expect(resolveEasing('cubic.in')(0.5), closeTo(0.125, 1e-9));
    });

    test('resolves a bare family name to its out variant', () {
      expect(
        resolveEasing('power2')(0.5),
        closeTo(resolveEasing('power2.out')(0.5), 1e-12),
      );
      expect(
        resolveEasing('sine')(0.3),
        closeTo(resolveEasing('sine.out')(0.3), 1e-12),
      );
    });

    test('is case and whitespace insensitive', () {
      expect(resolveEasing('  POWER1.InOut ')(0.5), closeTo(0.5, 1e-9));
      expect(isKnownEasing('Bounce.Out'), isTrue);
      expect(isKnownEasing('wobble'), isFalse);
    });

    test('pins every registered curve to its endpoints', () {
      for (final String name in motionPathEasingNames) {
        final Easing ease = resolveEasing(name);
        expect(ease(0), closeTo(0, 1e-9), reason: '$name at 0');
        expect(ease(1), closeTo(1, 1e-9), reason: '$name at 1');
      }
    });

    test('overshoots for back and elastic without breaking the ends', () {
      expect(resolveEasing('back.out')(0.6), greaterThan(1));
      expect(resolveEasing('elastic.out')(0.4), greaterThan(1));
      expect(resolveEasing('bounce.out')(0.5), lessThan(1));
    });

    test('falls back to linear for an unknown name', () {
      expect(
        resolveEasing('definitely-not-an-ease')(0.33),
        closeTo(0.33, 1e-9),
      );
    });
  });

  group('authored ease wiring', () {
    test('applies a per-segment ease from the authored stops', () {
      final List<MotionPathStop> stops = stopsFromKeyframe(<String, Object?>{
        'stops': <Object?>[
          <String, Object?>{'p': 0, 'v': 0},
          <String, Object?>{'p': 1, 'v': 100, 'ease': 'power1.in'},
        ],
      });
      expect(_n(interpolateStops(stops, 0.5)), closeTo(25, 1e-9));
    });

    test('inherits a keyframe-level ease when a stop authors none', () {
      final List<MotionPathStop> stops = stopsFromKeyframe(<String, Object?>{
        'ease': 'power1.in',
        'stops': <Object?>[
          <String, Object?>{'p': 0, 'v': 0},
          <String, Object?>{'p': 1, 'v': 100},
        ],
      });
      expect(_n(interpolateStops(stops, 0.5)), closeTo(25, 1e-9));
    });

    test('keeps a linear segment linear when none is authored', () {
      final List<MotionPathStop> stops = stopsFromKeyframe(<String, Object?>{
        'stops': <Object?>[
          <String, Object?>{'p': 0, 'v': 0, 'ease': 'none'},
          <String, Object?>{'p': 1, 'v': 100, 'ease': 'none'},
        ],
      });
      expect(_n(interpolateStops(stops, 0.5)), closeTo(50, 1e-9));
    });
  });

  group('colour values', () {
    test('parses the authored colour notations', () {
      expect(parseColorArgb('#f00'), 0xFFFF0000);
      expect(parseColorArgb('#FF0000'), 0xFFFF0000);
      expect(parseColorArgb('#ff000080'), 0x80FF0000);
      expect(parseColorArgb('rgb(255, 0, 0)'), 0xFFFF0000);
      expect(parseColorArgb('rgba(0, 0, 0, 0.5)'), 0x80000000);
      expect(parseColorArgb('transparent'), 0x00000000);
      expect(parseColorArgb('not-a-colour'), isNull);
    });

    test('interpolates channel by channel', () {
      expect(lerpArgb(0xFF000000, 0xFFFFFFFF, 0.5), 0xFF808080);
      expect(lerpArgb(0xFF000000, 0xFFFFFFFF, 0), 0xFF000000);
      expect(lerpArgb(0xFF000000, 0xFFFFFFFF, 1), 0xFFFFFFFF);
    });

    test('composes an authored colour track without bleeding carries', () {
      final MotionPathTrack track = MotionPathTrack(
        id: 'chip',
        keyframes: <String, Object?>{
          'color': <String, Object?>{
            'stops': <Object?>[
              <String, Object?>{'p': 0, 'v': '#000000'},
              <String, Object?>{'p': 1, 'v': '#ffffff'},
            ],
          },
        },
      );
      final MotionPathTrackRuntime runtime = MotionPathTrackRuntime(
        'chip',
        properties: propertiesFromTrack(track),
      );
      runtime.seek(0.5);
      // A naive lerp of the packed integers would land on 0xFF7F7F7F.
      expect(runtime.compose()['color'], 0xFF808080);
    });

    test('leaves non-colour properties on the numeric path', () {
      final MotionPathTrackRuntime runtime = MotionPathTrackRuntime(
        'box',
        properties: <String, List<MotionPathStop>>{
          'x': const <MotionPathStop>[
            MotionPathStop(progress: 0, value: 0),
            MotionPathStop(progress: 1, value: 10),
          ],
        },
      );
      runtime.seek(0.5);
      expect(_n(runtime.compose()['x']), closeTo(5, 1e-9));
    });
  });
}
