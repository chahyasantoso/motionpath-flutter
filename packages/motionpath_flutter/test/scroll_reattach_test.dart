import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathMotionRuntime _motion() => MotionPathMotionRuntime(
  id: 'scroll-lifecycle',
  tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('scene')],
);

Future<ScrollPosition> _pumpScrollable(
  WidgetTester tester,
  ScrollController controller,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SingleChildScrollView(
        controller: controller,
        child: const SizedBox(height: 800),
      ),
    ),
  );
  await tester.pump();
  return controller.position;
}

void main() {
  testWidgets('reattaching a reused position seeds instead of replaying', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = ScrollController();
    final ScrollPosition position = await _pumpScrollable(tester, controller);
    final List<MotionPathToggleAction> seen = <MotionPathToggleAction>[];
    final MotionPathViewportBinding binding = MotionPathViewportBinding(
      motion: _motion(),
      itemStart: 0,
      itemExtent: 200,
      viewportExtent: 600,
      start: 50,
      end: 150,
      onToggle: seen.add,
    );

    binding.attach(position);
    expect(binding.isAttached, isTrue);
    expect(binding.zone, MotionPathTriggerZone.before);
    expect(seen, isEmpty);

    controller.jumpTo(100);
    await tester.pump();
    controller.jumpTo(200);
    await tester.pump();
    expect(seen, <MotionPathToggleAction>[
      MotionPathToggleAction.enter,
      MotionPathToggleAction.leave,
    ]);

    binding.detach();
    expect(binding.isAttached, isFalse);
    expect(binding.zone, isNull);

    // The position is still parked past the window. Reattaching must not claim
    // the user scrolled through it again.
    binding.attach(position);
    expect(binding.zone, MotionPathTriggerZone.after);
    expect(seen.length, 2);

    binding.dispose();
    controller.dispose();
  });

  testWidgets('disposing mid-scroll stops sampling for good', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = ScrollController();
    final ScrollPosition position = await _pumpScrollable(tester, controller);
    int samples = 0;
    final MotionPathViewportBinding binding = MotionPathViewportBinding(
      motion: _motion(),
      itemStart: 0,
      itemExtent: 200,
      viewportExtent: 600,
      start: 0,
      end: 200,
      onSample: (_) => samples++,
    );

    binding.attach(position);
    controller.jumpTo(50);
    await tester.pump();
    final int beforeDisposal = samples;
    expect(beforeDisposal, greaterThan(1));

    binding.dispose();
    controller.jumpTo(150);
    await tester.pump();

    expect(samples, beforeDisposal);
    expect(binding.isAttached, isFalse);
    expect(binding.isDisposed, isTrue);
    expect(binding.sample.progress, 0);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
