import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('samples viewport geometry without starting the motion', () {
    final motion = MotionPathMotionRuntime(id: 'viewport', tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('a')]);
    final binding = MotionPathViewportPinBinding(
      motion: motion,
      delegate: const MotionPathViewportPinDelegate(),
      sampler: () => const MotionPathViewportSample(targetOffset: 250, targetExtent: 100, viewportExtent: 500),
    );
    binding.sample();
    expect(binding.progress, 0.5);
    expect(binding.isPinned, isTrue);
    expect(motion.progress, 0.5);
    expect(motion.playing, isFalse);
    binding.dispose();
  });

  test('detach resets state and disposal blocks sampling', () {
    final motion = MotionPathMotionRuntime(id: 'viewport', tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('a')]);
    final binding = MotionPathViewportPinBinding(
      motion: motion,
      delegate: const MotionPathViewportPinDelegate(),
      sampler: () => const MotionPathViewportSample(targetOffset: 0, targetExtent: 100, viewportExtent: 500),
    );
    binding.sample();
    binding.detach();
    expect(binding.progress, 0);
    expect(binding.isPinned, isFalse);
    binding.dispose();
    binding.sample();
    expect(binding.progress, 0);
    expect(motion.progress, 1);
  });
}
