import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';
import 'package:motionpath_flutter_example/carousel_demo.dart';
import 'package:motionpath_flutter_example/carousel_scene.dart';

/// Card titles in spawn order. Spawn order fixes the staggered offsets.
const List<String> _titles = <String>[
  'Fluid Motion Engine',
  'Zero Rebuilds',
  'Bezier Interpolation',
  'Tap to Remove',
  'Scrubbed Timeline',
  'Add a Card',
];

/// Authored opacity for a card playhead, read from the shared scene itself so
/// host assertions cannot drift from `carousel_scene.dart`.
double _sceneOpacityAt(double progress) {
  final MotionPathTrackRuntime track = carouselCardTrack('opacity-probe');
  track.seek(progress);
  return (track.compose()['opacity']! as num).toDouble();
}

/// Effective opacity the spawn host applies to a rendered card.
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
    expect(
      _hostOpacity(tester, _titles[0]),
      closeTo(_sceneOpacityAt(0.18), 1e-9),
    );
    expect(
      _hostOpacity(tester, _titles[1]),
      closeTo(_sceneOpacityAt(0.08), 1e-9),
    );
    for (final String title in _titles.sublist(2)) {
      expect(_hostOpacity(tester, title), closeTo(_sceneOpacityAt(0), 1e-9));
    }

    // Scroll offset 500 scrubs to 0.48, so the stagger walks the fade down the
    // card chain instead of flashing every card at once.
    await _scrollBy(tester, -200);
    for (final String title in _titles.sublist(0, 4)) {
      expect(_hostOpacity(tester, title), closeTo(_sceneOpacityAt(0.48), 1e-9));
    }
    expect(
      _hostOpacity(tester, _titles[4]),
      closeTo(_sceneOpacityAt(0.08), 1e-9),
    );
    expect(_hostOpacity(tester, _titles[5]), closeTo(_sceneOpacityAt(0), 1e-9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a card joins the shared scene without dropping survivors',
      (WidgetTester tester) async {
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
}
