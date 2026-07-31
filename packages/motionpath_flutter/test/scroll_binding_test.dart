import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('maps a scroll offset onto normalized progress', () {
    expect(
      MotionPathMotionScrollBinding.progressForOffset(
        pixels: 0,
        maxScrollExtent: 200,
      ),
      0,
    );
    expect(
      MotionPathMotionScrollBinding.progressForOffset(
        pixels: 100,
        maxScrollExtent: 200,
      ),
      0.5,
    );
    expect(
      MotionPathMotionScrollBinding.progressForOffset(
        pixels: 900,
        maxScrollExtent: 200,
      ),
      1,
    );
  });

  test('honours an explicit scroll window', () {
    expect(
      MotionPathMotionScrollBinding.progressForOffset(
        pixels: 40,
        maxScrollExtent: 500,
        start: 20,
        end: 60,
      ),
      0.5,
    );
    expect(
      MotionPathMotionScrollBinding.progressForOffset(
        pixels: 10,
        maxScrollExtent: 0,
        start: 20,
      ),
      0,
    );
  });

  test('seeks the motion without starting a second clock', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'scrubbed',
      tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('a')],
    );
    final MotionPathMotionScrollBinding binding = MotionPathMotionScrollBinding(
      motion: motion,
    );
    binding.seekFromOffset(pixels: 150, maxScrollExtent: 300);
    expect(motion.progress, 0.5);
    expect(motion.playing, isFalse);
    expect(binding.progress, 0.5);
    expect(binding.targetProgress, 0.5);
    expect(binding.isAttached, isFalse);
    binding.dispose();
  });

  test(
    'applies scrub smoothing only when the caller supplies elapsed time',
    () {
      final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
        id: 'scrubbed',
        tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('a')],
      );
      final MotionPathMotionScrollBinding binding =
          MotionPathMotionScrollBinding(motion: motion, scrub: 1);

      binding.seekFromOffset(pixels: 0, maxScrollExtent: 100, deltaSeconds: 0);
      binding.seekFromOffset(
        pixels: 100,
        maxScrollExtent: 100,
        deltaSeconds: 0.1,
      );

      expect(binding.targetProgress, 1);
      expect(binding.progress, closeTo(1 - 0.904837, 1e-5));
      expect(motion.progress, closeTo(binding.progress, 1e-9));
      binding.dispose();
    },
  );

  test('detach resets progress so a reused position starts clean', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'scrubbed',
      tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('a')],
    );
    final MotionPathMotionScrollBinding binding = MotionPathMotionScrollBinding(
      motion: motion,
    );
    binding.seekFromOffset(pixels: 80, maxScrollExtent: 100);
    binding.detach();
    expect(binding.progress, 0);
    expect(binding.targetProgress, 0);
    binding.dispose();
  });
}
