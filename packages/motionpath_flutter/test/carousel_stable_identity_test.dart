import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _child(String id) => MotionPathTrackRuntime(
      id,
      properties: <String, List<MotionPathStop>>{
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 100),
        ],
        'opacity': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 1),
          MotionPathStop(progress: 1, value: 0),
        ],
      },
    );

class _CardProbe extends StatefulWidget {
  const _CardProbe({required this.id, required this.onInit, super.key});

  final String id;
  final void Function(String id, State<_CardProbe> state) onInit;

  @override
  State<_CardProbe> createState() => _CardProbeState();
}

class _CardProbeState extends State<_CardProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit(widget.id, this);
  }

  @override
  Widget build(BuildContext context) => Text(widget.id);
}

void main() {
  testWidgets('stable card ids preserve expensive subtrees while patches update',
      (WidgetTester tester) async {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('carousel-parent'),
      childDuration: 10,
    );
    controller.spawn(_child('card-a'));
    controller.spawn(_child('card-b'), stagger: 5);
    final Map<String, State<_CardProbe>> states = <String, State<_CardProbe>>{};

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MotionPathSpawnView(
          controller: controller,
          itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) =>
              _CardProbe(
            key: ValueKey<String>('card-content-${instance.id}'),
            id: instance.id,
            onInit: (String id, State<_CardProbe> state) => states[id] = state,
          ),
        ),
      ),
    );
    final State<_CardProbe> firstA = states['card-a']!;
    final State<_CardProbe> firstB = states['card-b']!;

    controller.advanceTo(5);
    await tester.pump();

    expect(states['card-a'], same(firstA));
    expect(states['card-b'], same(firstB));
    expect(find.text('card-a'), findsOneWidget);
    expect(find.text('card-b'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
