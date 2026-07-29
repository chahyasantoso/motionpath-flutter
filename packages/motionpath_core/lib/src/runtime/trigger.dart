class MotionPathTrigger {
  MotionPathTrigger({this.autoplay = false, this.repeat = 0, this.yoyo = false, this.repeatDelay = 0, this.delay = 0});
  final bool autoplay;
  final int repeat;
  final bool yoyo;
  final double repeatDelay;
  final double delay;

  double progressAt(double elapsed, double duration) {
    if (duration <= 0) return 1;
    final shifted = elapsed - delay;
    if (shifted <= 0) return 0;
    final cycle = duration + repeatDelay;
    final index = (shifted / cycle).floor();
    if (repeat >= 0 && index > repeat) return yoyo && repeat.isOdd ? 0 : 1;
    final local = (shifted - index * cycle).clamp(0.0, duration);
    final value = local / duration;
    return yoyo && index.isOdd ? 1 - value : value;
  }
}
