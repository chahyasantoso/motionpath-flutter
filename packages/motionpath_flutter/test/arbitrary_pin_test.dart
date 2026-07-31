import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  testWidgets('arbitrary pin host follows sample paint offset', (WidgetTester tester) async {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(id: 'motion', tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('track')]);
    final MotionPathViewportBinding binding = MotionPathViewportBinding(motion: motion, itemStart: 200, itemExtent: 50, viewportExtent: 300, start: 100, end: 400, pin: true);
    binding.sampleFromOffset(200);
    await tester.pumpWidget(Stack(children: <Widget>[MotionPathArbitraryPinned(binding: binding, child: const SizedBox(key: ValueKey<String>('pinned'), height: 50, width: 50))]));
    expect(find.byKey(const ValueKey<String>('pinned')), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const ValueKey<String>('pinned'))).dy, 0);
    binding.dispose();
  });
}
