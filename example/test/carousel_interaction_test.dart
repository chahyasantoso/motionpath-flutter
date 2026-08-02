import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';
import 'package:motionpath_flutter_example/carousel_demo.dart';
import 'package:motionpath_flutter_example/carousel_scene.dart';

/// Card badges in spawn order. Spawn order fixes the staggered offsets.
const List<String> _badges = <String>[
  '01 / IMAGINATION',
  '02 / ARCHITECTURE',
  '03 / CREATIVE',
  '04 / INTERACTIVE',
  '05 / PERFORMANCE',
  '06 / DYNAMIC',
];

/// Card titles in spawn order.
const List<String> _titles = <String>[
  'Fluid Motion Engine',
  'Zero Rebuilds',
  'Bezier Interpolation',
  'Tap to Remove',
  'Scrubbed Timeline',
  'Add a Card',
];

/// Authored opacity for a card playhead, read from the shared scene itself so
/// the host assertions cannot drift from `carousel_scene.dart`.
double _sceneOpacityAt(double progress) {
  final MotionPathTrackRuntime track = carouselCardTrack('opacity-probe');
  track.seek(progress);
  return (track.compose()['opacity']! as num).toDouble();
}

/// Effective opacity applied by the spawn host to a rendered card.
double _hostOpacity(WidgetTester tester, String title) {
  final Finder card = find.text(title);
  expect(card, findsOneWidget);
  final Iterable<Opacity> layers = tester.widgetList<Opacity>(
    find.ancestor(
      of: card,
      matching: find.descendant(
        of: find.byType(MotionPathSpawnView),
        matching: find.byType(Opacity),
      ),
    ),
  );
  double opacity = 1;
  for (final Opacity layer in layers) {
    opacity *= layer.opacity;
  }
  return opacity;
}

Future<void> _scrollBy(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(ListView), Offset(0, dy));
  await tester.pump();
}

/// First card badge fully inside the visible stage, so a tap lands on a card
/// the user can actually see.
String? _tappableBadge(WidgetTester tester) {
  final Size screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final Rect stage = tester
      .getRect(find.byType(MotionPathSpawnView))
      .intersect(Rect.fromLTWH(0, 0, screen.width, screen.height));
  for (final String badge in _badges) {
    final Finder finder = find.text(badge);
    if (finder.evaluate().length != 1) continue;
    final Rect rect = tester.getRect(finder);
    if (stage.contains(rect.topLeft) && stage.contains(rect.center)) {
      return badge;
    }
  }
  return null;
}

void main() {
  testWidgets('forward scroll, reverse scroll, and re-entry keep every card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CarouselDemoPage()));
    await tester.pump();
    expect(find.text('0% scrubbed'), findsOneWidget);

    await _scrollBy(tester, -300);
    expect(find.text('12% scrubbed'), findsOneWidget);

    await _scrollBy(tester, 300);
    expect(find.text('0% scrubbed'), findsOneWidget);

    await _scrollBy(tester, -300);
    expect(find.text('12% scrubbed'), findsOneWidget);
    for (final String title in _titles) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.textContaining('6 cards'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('host card visibility tracks the authored opacity stops', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CarouselDemoPage()));
    await tester.pump();

    // Every card sits on the authored start boundary and is invisible.
    for (final String title in _titles) {
      expect(_hostOpacity(tester, title), closeTo(_sceneOpacityAt(0), 1e-9));
    }

    // Scroll offset 300 scrubs the parent timeline to 0.18.
    await _scrollBy(tester, -300);
    expect(_hostOpacity(tester, _titles[0]), closeTo(_sceneOpacityAt(0.18), 1e-9));
    expect(_hostOpacity(tester, _titles[1]), closeTo(_sceneOpacityAt(0.08), 1e-9));
    for (final String title in _titles.sublist(2)) {
      expect(_hostOpacity(tester, title), closeTo(_sceneOpacityAt(0), 1e-9));
    }

    // Scroll offset 800 pushes the lead card onto the authored fade-out ramp.
    await _scrollBy(tester, -500);
    expect(_hostOpacity(tester, _titles[0]), closeTo(_sceneOpacityAt(0.93), 1e-9));
    expect(_hostOpacity(tester, _titles[0]), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a card joins the shared scene without dropping survivors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CarouselDemoPage()));
    await tester.pump();
    expect(find.textContaining('6 cards'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.textContaining('7 cards'), findsOneWidget);
    for (final String title in _titles.sublist(1)) {
      expect(find.text(title), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a visible card removes it and keeps survivors mounted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CarouselDemoPage()));
    await tester.pump();
    await _scrollBy(tester, -300);

    final String? badge = _tappableBadge(tester);
    expect(badge, isNotNull, reason: 'no card is visible on the stage to tap');
    final Offset target =
        tester.getTopLeft(find.text(badge!)) + const Offset(1, 1);

    await tester.tapAt(target);
    await tester.pump();

    expect(find.text(badge), findsNothing);
    expect(find.textContaining('5 cards'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
