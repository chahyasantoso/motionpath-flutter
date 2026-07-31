import '../interpolation/interpolator.dart';

/// Samples one numeric value toward a fixed target over a finite duration.
class MotionPathValueTweener {
  MotionPathValueTweener({required double initial, required double target, required double duration, required Easing ease}) : _start = _finite(initial, 'initial'), _value = _finite(initial, 'initial'), _target = _finite(target, 'target'), _duration = _finiteNonNegative(duration, 'duration'), _ease = ease;
  static double _finite(double value, String name) { if (!value.isFinite) throw ArgumentError.value(value, name, 'must be finite'); return value; }
  static double _finiteNonNegative(double value, String name) { if (!value.isFinite || value < 0) throw ArgumentError.value(value, name, 'must be finite and non-negative'); return value; }
  final double _duration;
  final Easing _ease;
  double _start;
  double _value;
  double _target;
  double _elapsed = 0;
  double get value => _value;
  double get target => _target;
  bool get isComplete => _elapsed >= _duration || _value == _target;
  void retarget(double target) { _start = _value; _target = _finite(target, 'target'); _elapsed = 0; if (_duration <= 0) _value = _target; }
  double advance(double delta) { if (!delta.isFinite) throw ArgumentError.value(delta, 'delta', 'must be finite'); if (_duration <= 0 || delta <= 0) { if (_duration <= 0) _value = _target; return _value; } _elapsed = (_elapsed + delta).clamp(0.0, _duration).toDouble(); final double progress = _elapsed / _duration; _value = _start + (_target - _start) * _ease(progress); if (_elapsed >= _duration) _value = _target; return _value; }
}
