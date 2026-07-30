import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('samples viewport progress and pin state without a clock', () {
    final List<MotionPathViewportSample> samples =
        <MotionPathViewportSample>[];
    final MotionPathViewportPinBinding binding =
        MotionPathViewportPinBinding(
      contentOffset: 200,
      contentExtent: 100,
      viewportExtent: 400,
      start: 0,
      end: 200,
      onSample: samples.add,
    );

    final MotionPathViewportSample sample = binding.sample(pixels: 100);

    expect(sample.viewportTop, 100);
    expect(sample.viewportBottom, 200);
    expect(sample.progress, 0.5);
    expect(sample.isPinned, isFalse);
    expect(samples, isEmpty);
    binding.dispose();
  });

  test('pinning is reported inside the configured viewport window', () {
    final MotionPathViewportPinBinding binding =
        MotionPathViewportPinBinding(
      contentOffset: 200,
      contentExtent: 100,
      viewportExtent: 400,
      pinStart: 20,
      pinEnd: 100,
      onSample: (_) {},
    );

    expect(binding.sample(pixels: 190).isPinned, isTrue);
    expect(binding.sample(pixels: 0).isPinned, isFalse);
    binding.dispose();
  });
}
