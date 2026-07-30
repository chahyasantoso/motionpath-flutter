import 'dart:math' as math;

/// Normalized easing function over `[0, 1]`.
typedef Easing = double Function(double t);

double _clamp01(double value) {
  if (value.isNaN) {
    return 0.0;
  }
  if (value < 0) {
    return 0.0;
  }
  if (value > 1) {
    return 1.0;
  }
  return value;
}

double _power(double t, int exponent) {
  double result = t;
  for (int i = 1; i < exponent; i++) {
    result *= t;
  }
  return result;
}

/// Named easing curves that accept the JavaScript reference ease names.
///
/// Names follow the GSAP convention: a family plus an optional direction, for
/// example `power2.inOut`. A bare family resolves to its `.out` variant.
/// Unknown names fall back to [linear] rather than throwing, so a typo in a
/// cosmetic field never stops a project from animating.
class MotionPathEasing {
  /// No easing.
  static double linear(double t) => _clamp01(t);

  static const double _backOvershoot = 1.70158;

  static double _power1(double t) => _power(t, 2);

  static double _power2(double t) => _power(t, 3);

  static double _power3(double t) => _power(t, 4);

  static double _power4(double t) => _power(t, 5);

  static double _sine(double t) => 1.0 - math.cos(t * math.pi / 2);

  static double _expo(double t) =>
      t == 0 ? 0.0 : math.pow(2, 10 * t - 10).toDouble();

  static double _circ(double t) => 1.0 - math.sqrt(1 - t * t);

  static double _back(double t) =>
      (_backOvershoot + 1) * t * t * t - _backOvershoot * t * t;

  static const Map<String, Easing> _families = <String, Easing>{
    'power1': _power1,
    'power2': _power2,
    'power3': _power3,
    'power4': _power4,
    'quad': _power1,
    'cubic': _power2,
    'quart': _power3,
    'quint': _power4,
    'sine': _sine,
    'expo': _expo,
    'circ': _circ,
    'back': _back,
  };

  /// Every supported ease family name.
  static Iterable<String> get families => _families.keys;

  /// Resolves an authored ease name into an easing function.
  static Easing resolve(String? name) {
    if (name == null) {
      return linear;
    }
    final String normalized = name.trim();
    if (normalized.isEmpty ||
        normalized == 'none' ||
        normalized == 'linear' ||
        normalized == 'linear.none') {
      return linear;
    }
    final int dot = normalized.indexOf('.');
    final String family = dot == -1 ? normalized : normalized.substring(0, dot);
    final String direction = dot == -1 ? 'out' : normalized.substring(dot + 1);
    final Easing? base = _families[family];
    if (base == null) {
      return linear;
    }
    switch (direction) {
      case 'in':
        return (double t) => _clamp01(base(_clamp01(t)));
      case 'inOut':
        return (double t) {
          final double clamped = _clamp01(t);
          if (clamped < 0.5) {
            return _clamp01(base(clamped * 2) / 2);
          }
          return _clamp01(1 - base(2 - clamped * 2) / 2);
        };
      default:
        return (double t) => _clamp01(1 - base(1 - _clamp01(t)));
    }
  }
}
