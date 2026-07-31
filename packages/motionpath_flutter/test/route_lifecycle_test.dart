import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  testWidgets(
    'route teardown detaches and permanently disposes viewport state',
    (WidgetTester tester) async {
      final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
        id: 'route-motion',
        tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('scene')],
      );
      MotionPathViewportBinding? binding;
      final ScrollController controller = ScrollController();

      await tester.pumpWidget(
        _ViewportRouteHost(
          controller: controller,
          motion: motion,
          onBinding: (MotionPathViewportBinding value) => binding = value,
        ),
      );
      await tester.pump();

      expect(binding, isNotNull);
      expect(binding!.isAttached, isTrue);
      expect(binding!.isDisposed, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(binding!.isAttached, isFalse);
      expect(binding!.isDisposed, isTrue);
      expect(() => binding!.sampleFromOffset(50), returnsNormally);
      expect(binding!.sample.progress, 0);

      controller.dispose();
    },
  );
}

class _ViewportRouteHost extends StatefulWidget {
  const _ViewportRouteHost({
    required this.controller,
    required this.motion,
    required this.onBinding,
  });

  final ScrollController controller;
  final MotionPathMotionRuntime motion;
  final void Function(MotionPathViewportBinding binding) onBinding;

  @override
  State<_ViewportRouteHost> createState() => _ViewportRouteHostState();
}

class _ViewportRouteHostState extends State<_ViewportRouteHost> {
  late final MotionPathViewportBinding _binding = MotionPathViewportBinding(
    motion: widget.motion,
    itemStart: 100,
    itemExtent: 50,
    viewportExtent: 100,
    start: 0,
    end: 200,
  );

  @override
  void initState() {
    super.initState();
    widget.onBinding(_binding);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final ScrollPosition position = widget.controller.position;
      _binding.attach(position);
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: widget.controller,
    child: const SizedBox(height: 800),
  );

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }
}
