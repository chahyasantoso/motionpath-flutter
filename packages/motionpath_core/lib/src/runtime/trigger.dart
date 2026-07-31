/// Built-in trigger types.
enum MotionPathTriggerType {
  /// Advanced by the frame source.
  time,

  /// Paused, driven only through `seek`.
  manual,

  /// Driven by scroll position.
  scroll,
}

/// Trigger semantics for one motion.
class MotionPathTrigger {
  /// Creates a trigger.
  const MotionPathTrigger({
    this.type = MotionPathTriggerType.time,
    this.autoplay = false,
    this.repeat = 0,
    this.yoyo = false,
    this.repeatDelay = 0,
    this.delay = 0,
    this.scrub,
  });

  /// Reads a trigger from validated JSON.
  factory MotionPathTrigger.fromJson(Map<String, Object?> json) {
    final Object? rawType = json['type'];
    final MotionPathTriggerType type;
    switch (rawType) {
      case 'time':
        type = MotionPathTriggerType.time;
      case 'manual':
        type = MotionPathTriggerType.manual;
      case 'scroll':
        type = MotionPathTriggerType.scroll;
      default:
        throw StateError('Unknown MotionPath trigger type: $rawType');
    }
    final Object? repeat = json['repeat'];
    final Object? repeatDelay = json['repeatDelay'];
    final Object? delay = json['delay'];
    return MotionPathTrigger(
      type: type,
      autoplay: json['autoplay'] == true,
      repeat: repeat is num ? repeat.toInt() : 0,
      yoyo: json['yoyo'] == true,
      repeatDelay: repeatDelay is num ? repeatDelay.toDouble() : 0,
      delay: delay is num ? delay.toDouble() : 0,
      scrub: json['scrub'],
    );
  }

  /// Trigger type.
  final MotionPathTriggerType type;

  /// Whether mounting immediately starts playback.
  final bool autoplay;

  /// Repeat count. `-1` repeats forever.
  final int repeat;

  /// Whether repeats alternate direction.
  final bool yoyo;

  /// Pause between repeats, in seconds.
  final double repeatDelay;

  /// Delay before the first cycle, in seconds.
  final double delay;

  /// Scroll scrub setting: `true`, a number, or null.
  final Object? scrub;

  /// Whether this trigger scrubs on scroll rather than on time.
  bool get isScrub =>
      type == MotionPathTriggerType.scroll && (scrub == true || scrub is num);

  /// Normalized progress for [elapsed] seconds over a [duration].
  double progressAt(double elapsed, double duration) {
    if (duration <= 0) return 1;
    final double shifted = elapsed - delay;
    if (shifted <= 0) return 0;
    final double cycle = duration + repeatDelay;
    final int index = (shifted / cycle).floor();
    if (repeat >= 0 && index > repeat) {
      return yoyo && repeat.isOdd ? 0 : 1;
    }
    final double local = (shifted - index * cycle)
        .clamp(0.0, duration)
        .toDouble();
    final double value = local / duration;
    return yoyo && index.isOdd ? 1 - value : value;
  }

  /// Whether the trigger has exhausted every cycle by [elapsed].
  bool isFinished(double elapsed, double duration) {
    if (repeat < 0) return false;
    if (duration <= 0) return true;
    final double cycle = duration + repeatDelay;
    return elapsed - delay >= cycle * repeat + duration;
  }
}
