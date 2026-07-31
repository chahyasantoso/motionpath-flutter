import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('samples a fixed endpoint with the authored easing', () {
    final MotionPathValueTweener tweener = MotionPathValueTweener(
      initial: 0,
      target: 100,
      duration: 1,
      ease: resolveEasing('power2.in'),
    );

    expect(tweener.advance(0.5), closeTo(25, 1e-9));
    expect(tweener.isComplete, isFalse);
    expect(tweener.advance(0.5), 100);
    expect(tweener.isComplete, isTrue);
  });

  test('retargets from the current sample, not the original start', () {
    final MotionPathValueTweener tweener = MotionPathValueTweener(
      initial: 0,
      target: 100,
      duration: 1,
    );

    expect(tweener.advance(0.5), 50);
    tweener.retarget(200);
    expect(tweener.advance(0.5), 125);
  });

  test('zero duration resolves immediately and negative deltas are ignored', () {
    final MotionPathValueTweener tweener = MotionPathValueTweener(
      initial: 5,
      target: 20,
      duration: 0,
    );

    expect(tweener.value, 5);
    expect(tweener.advance(-1), 20);
    expect(tweener.isComplete, isTrue);
  });
}
