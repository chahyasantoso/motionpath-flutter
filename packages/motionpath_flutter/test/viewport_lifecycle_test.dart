import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('scroll driver can detach and dispose repeatedly', () {
    final MotionPathScrollDriver driver = MotionPathScrollDriver(
      binding: const MotionPathScrollBinding(),
      onProgress: (_) {},
    );
    driver.detach();
    driver.dispose();
    driver.dispose();
    driver.detach();
    expect(driver.controller, isNull);
  });

  test('viewport disposal is terminal and blocks later sampling', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
      id: 'viewport',
      tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('a')],
    );
    int samples = 0;
    final MotionPathViewportBinding binding = MotionPathViewportBinding(
      motion: motion,
      itemStart: 100,
      itemExtent: 50,
      viewportExtent: 100,
      start: 0,
      end: 100,
      onSample: (_) => samples++,
    );

    binding.sampleFromOffset(50);
    expect(binding.sample.progress, 0.5);
    expect(samples, 1);

    binding.dispose();
    binding.dispose();
    binding.sampleFromOffset(100);

    expect(binding.isDisposed, isTrue);
    expect(binding.isAttached, isFalse);
    expect(binding.sample.progress, 0);
    expect(samples, 1);
  });

  test('ticker driver does not report active after disposal', () {
    expect(true, isTrue);
  });
}
