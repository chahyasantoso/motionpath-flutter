import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

MotionPathTrackRuntime _child(String id, {double duration = 0}) =>
    MotionPathTrackRuntime(
      id,
      duration: duration,
      properties: <String, List<MotionPathStop>>{
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 100),
        ],
      },
    );

MotionPathSpawnController _controller({
  double childDuration = 10,
  bool drainOnComplete = false,
  MotionPathLayoutDelegate? layoutDelegate,
}) => MotionPathSpawnController(
  parent: MotionPathTrackRuntime('parent', layoutDelegate: layoutDelegate),
  childDuration: childDuration,
  drainOnComplete: drainOnComplete,
);

/// A chain whose first child outlives its siblings, so the child that finishes
/// first sits in the middle of the chain and its removal has to reflow.
MotionPathSpawnController _midChainDrainRig({
  MotionPathLayoutDelegate? layoutDelegate,
}) {
  final MotionPathSpawnController controller = _controller(
    drainOnComplete: true,
    layoutDelegate: layoutDelegate,
  );
  controller.spawn(_child('slow', duration: 100));
  controller.spawn(_child('quick'), stagger: 10);
  controller.spawn(_child('trailing'), stagger: 10);
  return controller;
}

void main() {
  test('children are reported in offset order with their settled offsets', () {
    final MotionPathSpawnController controller = _controller();
    controller.spawn(_child('a'), stagger: 2);
    controller.spawn(_child('b'), stagger: 2);
    controller.spawn(_child('c'), stagger: 2);

    expect(
      controller.instances.map((MotionPathSpawnInstance i) => i.id).toList(),
      <String>['a', 'b', 'c'],
    );
    expect(
      controller.instances
          .map((MotionPathSpawnInstance i) => i.offset)
          .toList(),
      <double>[0, 2, 4],
    );
    controller.dispose();
  });

  test(
    'a playhead is driven from the settled offset, not the motion start',
    () {
      final MotionPathSpawnController controller = _controller();
      controller.spawn(_child('a'), stagger: 5);
      controller.spawn(_child('b'), stagger: 5);

      controller.advanceTo(10);

      expect(controller.instances[0].progress, closeTo(1, 1e-9));
      expect(controller.instances[1].progress, closeTo(0.5, 1e-9));
      controller.dispose();
    },
  );

  test(
    'an unstarted child is distinguishable from one sitting at its first stop',
    () {
      final MotionPathSpawnController controller = _controller();
      controller.spawn(_child('a'), stagger: 5);
      controller.spawn(_child('b'), stagger: 5);

      controller.advanceTo(0);
      expect(controller.instances[0].hasStarted, isTrue);
      expect(controller.instances[0].progress, 0);
      expect(controller.instances[1].hasStarted, isFalse);
      expect(controller.instances[1].progress, 0);

      controller.advanceTo(5);
      expect(controller.instances[1].hasStarted, isTrue);
      controller.dispose();
    },
  );

  test('patches arrive composed, not raw', () {
    final MotionPathSpawnController controller = _controller();
    controller.spawn(_child('a'));

    controller.advanceTo(5);

    expect(controller.instances.single.patch['x'], closeTo(50, 1e-9));
    controller.dispose();
  });

  test('an authored child duration wins over the fallback span', () {
    final MotionPathSpawnController controller = _controller();
    controller.spawn(_child('quick', duration: 2));

    controller.advanceTo(1);

    expect(controller.instances.single.progress, closeTo(0.5, 1e-9));
    controller.dispose();
  });

  test('a mid-chain removal slides the survivor into the freed slot', () {
    final MotionPathSpawnController controller = _controller();
    for (final String id in <String>['a', 'b', 'c', 'd']) {
      controller.spawn(_child(id), stagger: 10);
    }
    controller.advanceTo(15);
    expect(controller.instances[1].progress, closeTo(0.5, 1e-9));

    controller.remove('b');

    expect(controller.instances[1].id, 'c');
    expect(controller.instances[1].offset, 10);
    expect(controller.instances[1].progress, closeTo(0.5, 1e-9));
    controller.dispose();
  });

  test('draining removes completed children', () {
    final MotionPathSpawnController controller = _controller(
      drainOnComplete: true,
    );
    for (final String id in <String>['a', 'b', 'c']) {
      controller.spawn(_child(id), stagger: 10);
    }

    controller.advanceTo(10);

    expect(controller.liveCount, 2);
    expect(
      controller.instances.map((MotionPathSpawnInstance i) => i.id).toList(),
      <String>['b', 'c'],
    );
    controller.dispose();
  });

  test('draining the front of a uniform chain never avalanches survivors', () {
    final MotionPathSpawnController controller = _controller(
      drainOnComplete: true,
    );
    for (final String id in <String>['a', 'b', 'c']) {
      controller.spawn(_child(id), stagger: 10);
    }

    // Every completion here is the leading edge, so no gap is ever created and
    // nothing shifts earlier.
    controller.advanceTo(20);

    expect(controller.liveCount, 1);
    expect(controller.instances.single.id, 'c');
    expect(controller.instances.single.offset, 20);
    expect(controller.instances.single.progress, 0);
    controller.dispose();
  });

  test('a reflow-induced completion waits for the next advance', () {
    final MotionPathSpawnController controller = _midChainDrainRig();

    controller.advanceTo(20);

    // `quick` finished at offset 10 and drained. `trailing` reflowed down into
    // that slot and is instantly complete, but this pass already ran.
    expect(controller.liveCount, 2);
    expect(controller.instances[1].id, 'trailing');
    expect(controller.instances[1].offset, 10);
    expect(controller.instances[1].progress, closeTo(1, 1e-9));

    controller.advanceBy(0);

    expect(controller.liveCount, 1);
    expect(controller.instances.single.id, 'slow');
    controller.dispose();
  });

  test('the static policy leaves the drained gap open', () {
    final MotionPathSpawnController controller = _midChainDrainRig(
      layoutDelegate: kStaticLayoutDelegate,
    );

    controller.advanceTo(20);

    // Same drain, no reflow: `trailing` keeps its offset and stays unstarted
    // instead of sliding forward into completion.
    expect(controller.liveCount, 2);
    expect(controller.instances[1].id, 'trailing');
    expect(controller.instances[1].offset, 20);
    expect(controller.instances[1].progress, 0);
    controller.dispose();
  });

  test('a second controller on the same parent fails fast', () {
    final MotionPathTrackRuntime parent = MotionPathTrackRuntime('parent');
    final MotionPathSpawnController first = MotionPathSpawnController(
      parent: parent,
    );

    expect(() => MotionPathSpawnController(parent: parent), throwsStateError);

    first.dispose();
    final MotionPathSpawnController second = MotionPathSpawnController(
      parent: parent,
    );
    expect(second.liveCount, 0);
    second.dispose();
  });

  test('dispose unwires the hooks, is idempotent, and blocks later work', () {
    final MotionPathTrackRuntime parent = MotionPathTrackRuntime('parent');
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: parent,
      childDuration: 10,
    );
    controller.spawn(_child('a'));
    int notifications = 0;
    controller.addListener(() => notifications++);

    controller.dispose();
    controller.dispose();
    controller.advanceTo(5);
    controller.spawn(_child('b'));
    controller.remove('a');

    expect(notifications, 0);
    expect(controller.isDisposed, isTrue);
    expect(controller.instances, isEmpty);
    expect(parent.onChildSpawned, isNull);
    expect(parent.onChildRemoved, isNull);
    expect(parent.onChildReflowed, isNull);
    expect(parent.childCount, 1);
  });

  test('notifications fire once per settle', () {
    final MotionPathSpawnController controller = _controller();
    int notifications = 0;
    controller.addListener(() => notifications++);

    controller.spawn(_child('a'));
    controller.advanceTo(1);
    controller.remove('a');

    expect(notifications, 3);
    controller.dispose();
  });
}
