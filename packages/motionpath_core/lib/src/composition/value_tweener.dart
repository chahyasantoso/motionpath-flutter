import '../interpolation/interpolator.dart';

/// Samples one numeric value toward a fixed target over a finite duration.
///
/// This is deliberately clock-neutral: callers provide frame deltas and own
/// scheduling. It is suitable for reflow animation without importing Flutter
/// or duplicating scroll scrub's exponential-decay formula.
class MotionPathValueTweener {
  /// Creates a tweener at [initial].
  MotionPathValueTweener({
    required double initial,
    required double target,
    required double duration,
    required Easing ease,
  })  : _start = _finite(initial, 'initial'),
        _value = _finite(initial, 'initial'),
        _target = _finite(target, 'target'),
        _duration = _finiteNonNegative(duration, 'duration'),
        _ease = ease;

  static double _finite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
    return value;
  }

  static double _finiteNonNegative(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        name,
        'must be finite and non-negative',
      );
    }
    return value;
  }

  final double _duration;
  final Easing _ease;
  double _start;
  double _value;
  double _target;
  double _elapsed = 0;

  /// Current sampled value.
  double get value => _value;

  /// Current endpoint.
  double get target => _target;

  /// Whether the fixed-duration tween has reached its endpoint.
  bool get isComplete => _elapsed >= _duration || _value == _target;

  /// Changes the endpoint and restarts the finite tween from the current value.
  void retarget(double target) {
    _start = _value;
    _target = _finite(target, 'target');
    _elapsed = 0;
    if (_duration <= 0) _value = _target;
  }

  /// Advances by [delta] seconds and returns the sampled value.
  double advance(double delta) {
    if (!delta.isFinite || delta < 0) {
      throw ArgumentError.value(
        delta,
        'delta',
        'must be finite and non-negative',
      );
    }
    if (_duration <= 0 || delta == 0) {
      if (_duration <= 0) _value = _target;
      return _value;
    }
    _elapsed = (_elapsed + delta).clamp(0.0, _duration).toDouble();
    final double progress = _elapsed / _duration;
    _value = _start + (_target - _start) * _ease(progress);
    if (_elapsed >= _duration) _value = _target;
    return _value;
  }
}
