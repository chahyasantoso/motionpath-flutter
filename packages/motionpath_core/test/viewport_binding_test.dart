import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

MotionPathViewportSample sample(double offset, {double viewport = 500}) => MotionPathViewportSample(targetOffset: offset, targetExtent: 100, viewportExtent: viewport);

void main() {
  const delegate = MotionPathViewportPinDelegate(enterAt: 1, exitAt: 0);
  test('maps viewport position to progress', () {
    expect(delegate.progressFor(sample(500)), 0);
    expect(delegate.progressFor(sample(250)), 0.5);
    expect(delegate.progressFor(sample(0)), 1);
  });
  test('clamps and reports pin state', () {
    expect(delegate.progressFor(sample(700)), 0);
    expect(delegate.progressFor(sample(-100)), 1);
    expect(delegate.isPinned(sample(250)), isTrue);
    expect(delegate.isPinned(sample(700)), isFalse);
  });
  test('degenerate viewport is safe', () {
    expect(delegate.progressFor(sample(0, viewport: 0)), 1);
    expect(delegate.isPinned(sample(0, viewport: 0)), isTrue);
  });
}
