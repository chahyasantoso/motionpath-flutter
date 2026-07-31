import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('advances a fixed-duration tween using the authored easing', () {
    final MotionPathValueTweener tweener = MotionPathValueTweener(
      initial: 0,
      target: 100,
      duration: 1,
      ease: resolveEasing('power2.in'),
    );

    expect(tweener.advance(0.5), closeTo(12.5, 1e-9));
    expect(tweener.isComplete, isFalse);
    expect(tweener.advance(0.5), 100);
    expect(tweener.isComplete, isTrue);
  });

  test('retargets from the current value without jumping', () {
    final MotionPathValueTweener tweener = MotionPathValueTweener(
      initial: 0,
      target: 100,
      duration: 1,
      ease: MotionPathInterpolators.linear,
    );

    expect(tweener.advance(0.25), 25);
    tweener.retarget(200);
    expect(tweener.value, 25);
    expect(tweener.advance(0.5), closeTo(112.5, 1e-9));
  });

  test('zero or negative duration snaps to the target', () {
    final MotionPathValueTweener tweener = MotionPathValueTweener(
      initial: 4,
      target: 9,
      duration: 0,
      ease: MotionPathInterpolators.linear,
    );

    expect(tweener.advance(0), 9);
    expect(tweener.isComplete, isTrue);
  });

  test('non-positive deltas do not move an active tween', () {
    final MotionPathValueTweener tweener = MotionPathValueTweener(
      initial: 4,
      target: 9,
      duration: 1,
      ease: MotionPathInterpolators.linear,
    );

    expect(tweener.advance(-1), 4);
    expect(tweener.advance(0), 4);
  });
}
