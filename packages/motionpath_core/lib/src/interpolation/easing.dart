import 'dart:math' as math;

import 'interpolator.dart';

/// Overshoot used by the `back` family, matching the reference runtime default.
const double kMotionPathBackOvershoot = 1.70158;

/// Period used by `elastic.in` and `elastic.out`.
const double kMotionPathElasticPeriod = 0.3;

/// Period used by `elastic.inOut`.
const double kMotionPathElasticInOutPeriod = 0.45;

double _clamp01(double t) {
  if (t.isNaN) return 0;
  if (t < 0) return 0;
  if (t > 1) return 1;
  return t;
}

double _pow(double base, num exponent) => math.pow(base, exponent).toDouble();

double _powerIn(double raw, int power) {
  final double t = _clamp01(raw);
  return _pow(t, power + 1);
}

double _powerOut(double raw, int power) {
  final double t = _clamp01(raw);
  return 1 - _pow(1 - t, power + 1);
}

double _powerInOut(double raw, int power) {
  final double t = _clamp01(raw);
  return t < 0.5
      ? _pow(2.0, power) * _pow(t, power + 1)
      : 1 - _pow(2.0, power) * _pow(1 - t, power + 1);
}

double _sineIn(double raw) => 1 - math.cos(_clamp01(raw) * math.pi / 2);

double _sineOut(double raw) => math.sin(_clamp01(raw) * math.pi / 2);

double _sineInOut(double raw) => -(math.cos(math.pi * _clamp01(raw)) - 1) / 2;

double _circIn(double raw) {
  final double t = _clamp01(raw);
  return 1 - math.sqrt(1 - t * t);
}

double _circOut(double raw) {
  final double t = _clamp01(raw) - 1;
  return math.sqrt(1 - t * t);
}

double _circInOut(double raw) {
  final double t = _clamp01(raw);
  if (t < 0.5) return (1 - math.sqrt(1 - 4 * t * t)) / 2;
  final double shifted = -2 * t + 2;
  return (math.sqrt(1 - shifted * shifted) + 1) / 2;
}

double _expoIn(double raw) {
  final double t = _clamp01(raw);
  return t == 0 ? 0 : _pow(2.0, 10 * t - 10);
}

double _expoOut(double raw) {
  final double t = _clamp01(raw);
  return t == 1 ? 1 : 1 - _pow(2.0, -10 * t);
}

double _expoInOut(double raw) {
  final double t = _clamp01(raw);
  if (t == 0) return 0;
  if (t == 1) return 1;
  return t < 0.5 ? _pow(2.0, 20 * t - 10) / 2 : (2 - _pow(2.0, -20 * t + 10)) / 2;
}

double _backIn(double raw) {
  final double t = _clamp01(raw);
  return (kMotionPathBackOvershoot + 1) * t * t * t - kMotionPathBackOvershoot * t * t;
}

double _backOut(double raw) {
  final double t = _clamp01(raw) - 1;
  return 1 + (kMotionPathBackOvershoot + 1) * t * t * t + kMotionPathBackOvershoot * t * t;
}

double _backInOut(double raw) {
  const double overshoot = kMotionPathBackOvershoot * 1.525;
  final double t = _clamp01(raw);
  if (t < 0.5) {
    final double scaled = 2 * t;
    return scaled * scaled * ((overshoot + 1) * scaled - overshoot) / 2;
  }
  final double scaled = 2 * t - 2;
  return (scaled * scaled * ((overshoot + 1) * scaled + overshoot) + 2) / 2;
}

double _elasticIn(double raw) {
  final double t = _clamp01(raw);
  if (t == 0 || t == 1) return t;
  const double angular = 2 * math.pi / kMotionPathElasticPeriod;
  return -_pow(2.0, 10 * t - 10) *
      math.sin((t - 1 - kMotionPathElasticPeriod / 4) * angular);
}

double _elasticOut(double raw) {
  final double t = _clamp01(raw);
  if (t == 0 || t == 1) return t;
  const double angular = 2 * math.pi / kMotionPathElasticPeriod;
  return _pow(2.0, -10 * t) * math.sin((t - kMotionPathElasticPeriod / 4) * angular) + 1;
}

double _elasticInOut(double raw) {
  final double t = _clamp01(raw);
  if (t == 0 || t == 1) return t;
  const double angular = 2 * math.pi / kMotionPathElasticInOutPeriod;
  final double phase = math.sin((20 * t - 11.125) * angular);
  return t < 0.5
      ? -(_pow(2.0, 20 * t - 10) * phase) / 2
      : (_pow(2.0, -20 * t + 10) * phase) / 2 + 1;
}

double _bounceOut(double raw) {
  const double amplitude = 7.5625;
  const double divisor = 2.75;
  final double t = _clamp01(raw);
  if (t < 1 / divisor) return amplitude * t * t;
  if (t < 2 / divisor) {
    final double shifted = t - 1.5 / divisor;
    return amplitude * shifted * shifted + 0.75;
  }
  if (t < 2.5 / divisor) {
    final double shifted = t - 2.25 / divisor;
    return amplitude * shifted * shifted + 0.9375;
  }
  final double shifted = t - 2.625 / divisor;
  return amplitude * shifted * shifted + 0.984375;
}

double _bounceIn(double raw) => 1 - _bounceOut(1 - _clamp01(raw));

double _bounceInOut(double raw) {
  final double t = _clamp01(raw);
  return t < 0.5 ? (1 - _bounceOut(1 - 2 * t)) / 2 : (1 + _bounceOut(2 * t - 1)) / 2;
}

/// Suffixes an authored ease name may carry, normalized to lower case.
const List<String> _suffixes = <String>['', '.in', '.out', '.inout'];

/// Reference aliases: `quad` is `power1`, `cubic` is `power2`, and so on.
const Map<String, String> _aliases = <String, String>{
  'quad': 'power1',
  'cubic': 'power2',
  'quart': 'power3',
  'quint': 'power4',
  'strong': 'power4',
};

Map<String, Easing> _buildEasings() {
  final Map<String, Easing> table = <String, Easing>{
    'none': MotionPathInterpolators.linear,
    'linear': MotionPathInterpolators.linear,
    'linear.none': MotionPathInterpolators.linear,
  };

  void addFamily(String name, Easing easeIn, Easing easeOut, Easing easeInOut) {
    table['$name.in'] = easeIn;
    table['$name.out'] = easeOut;
    table['$name.inout'] = easeInOut;
    // A bare family name means `.out` in the reference runtime.
    table[name] = easeOut;
  }

  for (var power = 1; power <= 4; power++) {
    final int exponent = power;
    addFamily(
      'power$exponent',
      (double t) => _powerIn(t, exponent),
      (double t) => _powerOut(t, exponent),
      (double t) => _powerInOut(t, exponent),
    );
  }
  for (final MapEntry<String, String> alias in _aliases.entries) {
    for (final String suffix in _suffixes) {
      table['${alias.key}$suffix'] = table['${alias.value}$suffix']!;
    }
  }

  addFamily('sine', _sineIn, _sineOut, _sineInOut);
  addFamily('circ', _circIn, _circOut, _circInOut);
  addFamily('expo', _expoIn, _expoOut, _expoInOut);
  addFamily('back', _backIn, _backOut, _backInOut);
  addFamily('elastic', _elasticIn, _elasticOut, _elasticInOut);
  addFamily('bounce', _bounceIn, _bounceOut, _bounceInOut);

  return Map<String, Easing>.unmodifiable(table);
}

final Map<String, Easing> _easings = _buildEasings();

/// Every ease name this build understands, lower cased.
///
/// Useful for asserting authored projects only reference curves that exist
/// instead of silently degrading to linear at runtime.
Iterable<String> get motionPathEasingNames => _easings.keys;

/// True when [name] resolves to a real curve rather than the linear fallback.
bool isKnownEasing(String name) => _easings.containsKey(name.trim().toLowerCase());

/// Resolves an authored `stops[].ease` value into an [Easing] curve.
///
/// Names are matched case-insensitively, `power1` style bare families resolve to
/// their `.out` variant, and anything unknown falls back to linear so a typo
/// degrades the motion instead of crashing the runtime.
Easing resolveEasing(Object? authored) {
  if (authored is Easing) return authored;
  if (authored is! String) return MotionPathInterpolators.linear;
  final String key = authored.trim().toLowerCase();
  if (key.isEmpty) return MotionPathInterpolators.linear;
  return _easings[key] ?? MotionPathInterpolators.linear;
}
