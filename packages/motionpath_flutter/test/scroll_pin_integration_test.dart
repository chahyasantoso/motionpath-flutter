import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

const Key _pinnedKey = ValueKey<String>('arbitrary-pin');

const double _viewportExtent = 600;
const double _itemStart = 400;
const double _itemExtent = 200;
const double _windowStart = 400;
const double _windowEnd = 900;

MotionPathMotionRuntime _motion() => MotionPathMotionRuntime(
  id: 'arbitrary-pin',
  tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('scene')],
);

MotionPathViewportBinding _binding({
  void Function(MotionPathToggleAction action)? onToggle,
}) => MotionPathViewportBinding(
  motion: _motion(),
  itemStart: _itemStart,
  itemExtent: _itemExtent,
  viewportExtent: _viewportExtent,
  start: _windowStart,
  end: _windowEnd,
  pin: true,
  onToggle: onToggle,
);

/// Pumps a viewport-sized stack with the pin host overlaying a scrollable.
///
/// The stack is anchored at the top left of the test surface, so the pinned
/// child's global `dy` is the sampled paint offset with no bookkeeping.
Future<void> _pumpHost(
  WidgetTester tester, {
  required ScrollController controller,
  required MotionPathViewportBinding binding,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          height: _viewportExtent,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: controller,
                  child: const SizedBox(height: 2000),
                ),
              ),
              MotionPathArbitraryPinned(
                binding: binding,
                child: const SizedBox(
                  key: _pinnedKey,
                  height: _itemExtent,
                  width: 200,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _pinnedTop(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_pinnedKey)).dy;

void main() {
  group('viewport sample values', () {
    test('a pinned sample stays visible past its unpinned intersection', () {
      final MotionPathViewportSample sample =
          MotionPathViewportBinding.sampleAt(
            scrollPixels: 800,
            itemStart: _itemStart,
            itemExtent: _itemExtent,
            viewportExtent: _viewportExtent,
            start: _windowStart,
            end: _windowEnd,
            pin: true,
          );

      // The unpinned geometry is long gone, but the host is still holding the
      // section at the leading edge.
      expect(sample.localOffset, -400);
      expect(sample.pinned, isTrue);
      expect(sample.paintOffset, 0);
      expect(sample.visible, isTrue);
    });

    test('releasing the pin past the window hides the section again', () {
      final MotionPathViewportSample sample =
          MotionPathViewportBinding.sampleAt(
            scrollPixels: 1000,
            itemStart: _itemStart,
            itemExtent: _itemExtent,
            viewportExtent: _viewportExtent,
            start: _windowStart,
            end: _windowEnd,
            pin: true,
          );

      expect(sample.progress, 1);
      expect(sample.pinned, isFalse);
      expect(sample.visible, isFalse);
    });

    test('samples compare by value so hosts can skip unchanged frames', () {
      MotionPathViewportSample at(double pixels) =>
          MotionPathViewportBinding.sampleAt(
            scrollPixels: pixels,
            itemStart: _itemStart,
            itemExtent: _itemExtent,
            viewportExtent: _viewportExtent,
            start: _windowStart,
            end: _windowEnd,
            pin: true,
          );

      expect(at(500), at(500));
      expect(at(500).hashCode, at(500).hashCode);
      expect(at(500), isNot(at(520)));
    });
  });

  testWidgets('the pin host tracks a real scroll position through its window', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = ScrollController();
    final MotionPathViewportBinding binding = _binding();

    await _pumpHost(tester, controller: controller, binding: binding);
    binding.attach(controller.position);
    await tester.pump();

    // Approaching the window the section rides the scrolled content.
    expect(binding.sample.pinned, isFalse);
    expect(_pinnedTop(tester), 400);

    controller.jumpTo(200);
    await tester.pump();
    expect(binding.sample.pinned, isFalse);
    expect(_pinnedTop(tester), 200);

    // Inside the window the section is held at the leading edge while the
    // motion is seeked from the same sample.
    controller.jumpTo(500);
    await tester.pump();
    expect(binding.sample.pinned, isTrue);
    expect(_pinnedTop(tester), 0);
    expect(binding.motion.progress, closeTo(0.2, 1e-9));

    controller.jumpTo(800);
    await tester.pump();
    expect(binding.sample.pinned, isTrue);
    expect(find.byKey(_pinnedKey), findsOneWidget);
    expect(_pinnedTop(tester), 0);
    expect(binding.motion.progress, closeTo(0.8, 1e-9));

    // Past the window the pin is released and the section leaves.
    controller.jumpTo(1000);
    await tester.pump();
    expect(binding.sample.pinned, isFalse);
    expect(binding.sample.visible, isFalse);
    expect(binding.motion.progress, 1);
    expect(find.byKey(_pinnedKey), findsNothing);

    expect(tester.takeException(), isNull);
    binding.dispose();
    controller.dispose();
  });

  testWidgets('scrolling back out reports crossings in travel order', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = ScrollController();
    final List<MotionPathToggleAction> seen = <MotionPathToggleAction>[];
    final MotionPathViewportBinding binding = _binding(onToggle: seen.add);

    await _pumpHost(tester, controller: controller, binding: binding);
    binding.attach(controller.position);
    await tester.pump();
    expect(seen, isEmpty);

    controller.jumpTo(500);
    await tester.pump();
    controller.jumpTo(1000);
    await tester.pump();
    controller.jumpTo(500);
    await tester.pump();
    controller.jumpTo(0);
    await tester.pump();

    expect(seen, <MotionPathToggleAction>[
      MotionPathToggleAction.enter,
      MotionPathToggleAction.leave,
      MotionPathToggleAction.enterBack,
      MotionPathToggleAction.leaveBack,
    ]);
    expect(_pinnedTop(tester), 400);

    expect(tester.takeException(), isNull);
    binding.dispose();
    controller.dispose();
  });

  testWidgets('tearing the host down mid-pin unwires it from the binding', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = ScrollController();
    final MotionPathViewportBinding binding = _binding();

    await _pumpHost(tester, controller: controller, binding: binding);
    binding.attach(controller.position);
    controller.jumpTo(500);
    await tester.pump();
    expect(_pinnedTop(tester), 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    // The scroll view is gone, but the binding outlives it. Sampling must not
    // reach a disposed State.
    binding.sampleFromOffset(650);
    await tester.pump();

    expect(find.byKey(_pinnedKey), findsNothing);
    expect(binding.sample.pinned, isTrue);
    expect(tester.takeException(), isNull);

    binding.dispose();
    controller.dispose();
  });
}
