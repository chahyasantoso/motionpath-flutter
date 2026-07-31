import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathMotionRuntime _motion() => MotionPathMotionRuntime(
  id: 'viewport',
  tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('a')],
);

void main() {
  test('reports window crossings without replaying the first sample', () {
    final List<MotionPathToggleAction> seen = <MotionPathToggleAction>[];
    final MotionPathViewportBinding binding = MotionPathViewportBinding(
      motion: _motion(),
      itemStart: 0,
      itemExtent: 100,
      viewportExtent: 200,
      start: 100,
      end: 200,
      onToggle: seen.add,
    );

    binding.sampleFromOffset(0);
    expect(seen, isEmpty);
    expect(binding.zone, MotionPathTriggerZone.before);

    binding.sampleFromOffset(150);
    binding.sampleFromOffset(250);
    binding.sampleFromOffset(150);
    binding.sampleFromOffset(0);

    expect(seen, <MotionPathToggleAction>[
      MotionPathToggleAction.enter,
      MotionPathToggleAction.leave,
      MotionPathToggleAction.enterBack,
      MotionPathToggleAction.leaveBack,
    ]);
    binding.dispose();
  });

  test('a crossing handler reads the sample that caused it', () {
    final List<double> progressAtToggle = <double>[];
    late final MotionPathViewportBinding binding;
    binding = MotionPathViewportBinding(
      motion: _motion(),
      itemStart: 0,
      itemExtent: 100,
      viewportExtent: 200,
      start: 100,
      end: 200,
      onToggle: (_) => progressAtToggle.add(binding.sample.progress),
    );

    binding.sampleFromOffset(0);
    binding.sampleFromOffset(150);

    expect(progressAtToggle, <double>[0.5]);
    binding.dispose();
  });

  test('detach re-seeds so a reused viewport does not replay a crossing', () {
    final List<MotionPathToggleAction> seen = <MotionPathToggleAction>[];
    final MotionPathViewportBinding binding = MotionPathViewportBinding(
      motion: _motion(),
      itemStart: 0,
      itemExtent: 100,
      viewportExtent: 200,
      start: 100,
      end: 200,
      onToggle: seen.add,
    );

    binding.sampleFromOffset(0);
    binding.detach();
    expect(binding.zone, isNull);

    binding.sampleFromOffset(250);
    expect(seen, isEmpty);
    expect(binding.zone, MotionPathTriggerZone.after);

    binding.dispose();
    binding.sampleFromOffset(0);
    expect(seen, isEmpty);
  });

  test('an inverted authored window fails fast at construction', () {
    expect(
      () => MotionPathViewportBinding(
        motion: _motion(),
        itemStart: 0,
        itemExtent: 100,
        viewportExtent: 200,
        start: 200,
        end: 100,
      ),
      throwsArgumentError,
    );
  });
}
