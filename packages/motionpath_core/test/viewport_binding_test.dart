import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

MotionPathViewportSample _sample(double offset) =>
    MotionPathViewportSample(
      targetOffset: offset,
      targetExtent: 100,
      viewportExtent: 500,
    );

void main() {
  const MotionPathViewportPinDelegate delegate =
      MotionPathViewportPinDelegate(enterAt: 1, exitAt: 0);

  test('maps the viewport pin window to normalized progress', () {
    expect(delegate.progressFor(_sample(500)), 0);
    expect(delegate.progressFor(_sample(250)), 0.5);
    expect(delegate.progressFor(_sample(0)), 1);
  });

  test('clamps outside the viewport pin window', () {
    expect(delegate.progressFor(_sample(700)), 0);
    expect(delegate.progressFor(_sample(-100)), 1);
  });

  test('reports pin state independently from progress', () {
    expect(delegate.isPinned(_sample(500)), isTrue);
    expect(delegate.isPinned(_sample(250)), isTrue);
    expect(delegate.isPinned(_sample(0)), isTrue);
    expect(delegate.isPinned(_sample(600)), isFalse);
  });

  test('degenerate viewport is safe', () {
    const MotionPathViewportSample sample = MotionPathViewportSample(
      targetOffset: 0,
      targetExtent: 10,
      viewportExtent: 0,
    );
    expect(delegate.progressFor(sample), 1);
    expect(delegate.isPinned(sample), isTrue);
  });
}
