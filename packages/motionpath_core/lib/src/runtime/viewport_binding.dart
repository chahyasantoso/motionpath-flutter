import 'package:meta/meta.dart';

@immutable
class MotionPathViewportSample {
  const MotionPathViewportSample({
    required this.targetOffset,
    required this.targetExtent,
    required this.viewportExtent,
    this.progress = 0,
    this.isPinned = false,
  });

  final double targetOffset;
  final double targetExtent;
  final double viewportExtent;
  final double progress;
  final bool isPinned;

  double get viewportTop => targetOffset;
  double get viewportBottom => targetOffset + targetExtent;
}

class MotionPathViewportPinDelegate {
  const MotionPathViewportPinDelegate({this.enterAt = 1, this.exitAt = 0});
  final double enterAt;
  final double exitAt;

  double progressFor(MotionPathViewportSample sample) {
    final double span = sample.viewportExtent * (exitAt - enterAt);
    if (sample.viewportExtent <= 0 || span == 0) {
      return sample.targetOffset <= sample.viewportExtent * enterAt ? 1 : 0;
    }
    return ((sample.targetOffset - sample.viewportExtent * enterAt) / span).clamp(0.0, 1.0).toDouble();
  }

  bool isPinned(MotionPathViewportSample sample) {
    final double low = sample.viewportExtent * (enterAt < exitAt ? enterAt : exitAt);
    final double high = sample.viewportExtent * (enterAt > exitAt ? enterAt : exitAt);
    return sample.targetOffset >= low && sample.targetOffset <= high;
  }
}
