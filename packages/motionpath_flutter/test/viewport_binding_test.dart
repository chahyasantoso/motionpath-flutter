import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('samples visibility, progress, and local geometry', () {
    final MotionPathViewportSample sample =
        MotionPathViewportBinding.sampleAt(
      scrollPixels: 120,
      itemStart: 100,
      itemExtent: 80,
      viewportExtent: 300,
      start: 100,
      end: 300,
    );

    expect(sample.localOffset, -20);
    expect(sample.progress, 0.1);
    expect(sample.visible, isTrue);
    expect(sample.pinned, isFalse);
    expect(sample.paintOffset, -20);
  });

  test('pins only inside the authored scroll window', () {
    final MotionPathViewportSample before =
        MotionPathViewportBinding.sampleAt(
      scrollPixels: 0,
      itemStart: 100,
      itemExtent: 40,
      viewportExtent: 200,
      start: 50,
      end: 150,
      pin: true,
    );
    final MotionPathViewportSample during =
        MotionPathViewportBinding.sampleAt(
      scrollPixels: 100,
      itemStart: 100,
      itemExtent: 40,
      viewportExtent: 200,
      start: 50,
      end: 150,
      pin: true,
    );
    final MotionPathViewportSample after =
        MotionPathViewportBinding.sampleAt(
      scrollPixels: 200,
      itemStart: 100,
      itemExtent: 40,
      viewportExtent: 200,
      start: 50,
      end: 150,
      pin: true,
    );

    expect(before.pinned, isFalse);
    expect(during.pinned, isTrue);
    expect(during.paintOffset, 0);
    expect(after.pinned, isFalse);
  });

  test('binding seeks without starting a clock and resets on detach', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'viewport',
      tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('a')],
    );
    final MotionPathViewportBinding binding = MotionPathViewportBinding(
      motion: motion,
      itemStart: 0,
      itemExtent: 100,
      viewportExtent: 200,
      start: 0,
      end: 100,
    );

    binding.sampleFromOffset(50);
    expect(motion.progress, 0.5);
    expect(motion.playing, isFalse);
    expect(binding.sample.progress, 0.5);
    binding.detach();
    expect(binding.isAttached, isFalse);
    expect(binding.sample.progress, 0);
    binding.dispose();
  });
}
