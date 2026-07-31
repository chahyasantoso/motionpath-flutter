import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

const Key _pinnedKey = ValueKey<String>('pinned');

Widget _host({
  required ScrollController controller,
  required List<double> progresses,
  double extent = 100,
  double pinExtent = 200,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CustomScrollView(
    controller: controller,
    slivers: <Widget>[
      MotionPathPinnedHeader(
        extent: extent,
        pinExtent: pinExtent,
        builder: (BuildContext context, double progress) {
          progresses.add(progress);
          return const SizedBox.expand(key: _pinnedKey);
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 2000)),
    ],
  ),
);

void main() {
  test('pin progress normalizes the sliver shrink offset', () {
    expect(
      MotionPathPinnedHeaderDelegate.progressFor(
        shrinkOffset: 0,
        pinExtent: 200,
      ),
      0,
    );
    expect(
      MotionPathPinnedHeaderDelegate.progressFor(
        shrinkOffset: 50,
        pinExtent: 200,
      ),
      0.25,
    );
    expect(
      MotionPathPinnedHeaderDelegate.progressFor(
        shrinkOffset: 900,
        pinExtent: 200,
      ),
      1,
    );
  });

  test('a zero runway reports binary progress instead of dividing by zero', () {
    expect(
      MotionPathPinnedHeaderDelegate.progressFor(shrinkOffset: 0, pinExtent: 0),
      0,
    );
    expect(
      MotionPathPinnedHeaderDelegate.progressFor(shrinkOffset: 1, pinExtent: 0),
      1,
    );
  });

  test('an unusable extent fails fast', () {
    Widget builder(BuildContext context, double progress) => const SizedBox();

    expect(
      () => MotionPathPinnedHeaderDelegate(
        extent: 0,
        pinExtent: 100,
        builder: builder,
      ),
      throwsArgumentError,
    );
    expect(
      () => MotionPathPinnedHeaderDelegate(
        extent: 100,
        pinExtent: -1,
        builder: builder,
      ),
      throwsArgumentError,
    );
  });

  test('the runway is the authored extent plus the pin distance', () {
    final MotionPathPinnedHeaderDelegate delegate =
        MotionPathPinnedHeaderDelegate(
          extent: 100,
          pinExtent: 200,
          builder: (BuildContext context, double progress) => const SizedBox(),
        );

    expect(delegate.minExtent, 100);
    expect(delegate.maxExtent, 300);
  });

  testWidgets('the section stays at the leading edge across its runway', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = ScrollController();
    final List<double> progresses = <double>[];

    await tester.pumpWidget(
      _host(controller: controller, progresses: progresses),
    );

    expect(progresses.last, 0);
    expect(tester.getTopLeft(find.byKey(_pinnedKey)).dy, 0);

    controller.jumpTo(100);
    await tester.pump();
    expect(progresses.last, closeTo(0.5, 1e-9));
    expect(tester.getTopLeft(find.byKey(_pinnedKey)).dy, 0);

    controller.jumpTo(400);
    await tester.pump();
    expect(progresses.last, 1);
    expect(tester.getTopLeft(find.byKey(_pinnedKey)).dy, 0);

    controller.jumpTo(0);
    await tester.pump();
    expect(progresses.last, 0);

    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
