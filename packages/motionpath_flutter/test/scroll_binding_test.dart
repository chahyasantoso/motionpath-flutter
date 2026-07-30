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
    final MotionPathMotionScrollBinding binding =
        MotionPathMotionScrollBinding(motion: motion);
    binding.seekFromOffset(pixels: 150, maxScrollExtent: 300);
    expect(motion.progress, 0.5);
    expect(motion.playing, isFalse);
    expect(binding.isAttached, isFalse);
    binding.dispose();
  });
}
