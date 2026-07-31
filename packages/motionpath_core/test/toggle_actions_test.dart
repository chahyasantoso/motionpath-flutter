import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

List<MotionPathToggleAction> _drive(
  MotionPathToggleStateMachine machine,
  double value,
) => machine.updateForValue(value: value, start: 100, end: 200);

void main() {
  test('the first sample seeds silently', () {
    final List<MotionPathToggleAction> seen = <MotionPathToggleAction>[];
    final MotionPathToggleStateMachine machine = MotionPathToggleStateMachine(
      onAction: seen.add,
    );

    expect(machine.isSeeded, isFalse);
    expect(_drive(machine, 150), isEmpty);
    expect(machine.zone, MotionPathTriggerZone.inside);
    expect(seen, isEmpty);
  });

  test('reports one crossing per boundary in travel order', () {
    final List<MotionPathToggleAction> seen = <MotionPathToggleAction>[];
    final MotionPathToggleStateMachine machine = MotionPathToggleStateMachine(
      onAction: seen.add,
    );

    _drive(machine, 0);
    expect(_drive(machine, 150), <MotionPathToggleAction>[
      MotionPathToggleAction.enter,
    ]);
    expect(_drive(machine, 250), <MotionPathToggleAction>[
      MotionPathToggleAction.leave,
    ]);
    expect(_drive(machine, 150), <MotionPathToggleAction>[
      MotionPathToggleAction.enterBack,
    ]);
    expect(_drive(machine, 0), <MotionPathToggleAction>[
      MotionPathToggleAction.leaveBack,
    ]);
    expect(seen, <MotionPathToggleAction>[
      MotionPathToggleAction.enter,
      MotionPathToggleAction.leave,
      MotionPathToggleAction.enterBack,
      MotionPathToggleAction.leaveBack,
    ]);
  });

  test('a sample that skips the window still reports both crossings', () {
    final MotionPathToggleStateMachine machine = MotionPathToggleStateMachine();

    _drive(machine, 0);
    expect(_drive(machine, 900), <MotionPathToggleAction>[
      MotionPathToggleAction.enter,
      MotionPathToggleAction.leave,
    ]);
    expect(_drive(machine, -900), <MotionPathToggleAction>[
      MotionPathToggleAction.enterBack,
      MotionPathToggleAction.leaveBack,
    ]);
  });

  test('staying inside a zone reports nothing', () {
    final MotionPathToggleStateMachine machine = MotionPathToggleStateMachine();

    _drive(machine, 120);
    expect(_drive(machine, 180), isEmpty);
    expect(_drive(machine, 200), isEmpty);
    expect(machine.zone, MotionPathTriggerZone.inside);
  });

  test('reset re-seeds instead of replaying the crossing it skipped', () {
    final MotionPathToggleStateMachine machine = MotionPathToggleStateMachine();

    _drive(machine, 0);
    machine.reset();
    expect(machine.isSeeded, isFalse);
    expect(_drive(machine, 250), isEmpty);
    expect(machine.zone, MotionPathTriggerZone.after);
  });

  test('endpoints are inside and a zero-span window keeps a point zone', () {
    expect(
      MotionPathToggleStateMachine.zoneFor(value: 100, start: 100, end: 200),
      MotionPathTriggerZone.inside,
    );
    expect(
      MotionPathToggleStateMachine.zoneFor(value: 200, start: 100, end: 200),
      MotionPathTriggerZone.inside,
    );
    expect(
      MotionPathToggleStateMachine.zoneFor(value: 50, start: 50, end: 50),
      MotionPathTriggerZone.inside,
    );
  });

  test('an inverted or non-finite window fails fast', () {
    expect(
      () =>
          MotionPathToggleStateMachine.zoneFor(value: 0, start: 200, end: 100),
      throwsArgumentError,
    );
    expect(
      () => MotionPathToggleStateMachine.zoneFor(
        value: 0,
        start: 0,
        end: double.nan,
      ),
      throwsArgumentError,
    );
    expect(
      () => MotionPathToggleStateMachine.zoneFor(
        value: double.infinity,
        start: 0,
        end: 1,
      ),
      throwsArgumentError,
    );
  });

  test('a callback that samples again re-enters against the new zone', () {
    late final MotionPathToggleStateMachine machine;
    final List<MotionPathToggleAction> seen = <MotionPathToggleAction>[];
    machine = MotionPathToggleStateMachine(
      onAction: (MotionPathToggleAction action) {
        seen.add(action);
        if (action == MotionPathToggleAction.enter) _drive(machine, 250);
      },
    );

    _drive(machine, 0);
    _drive(machine, 150);

    expect(seen, <MotionPathToggleAction>[
      MotionPathToggleAction.enter,
      MotionPathToggleAction.leave,
    ]);
    expect(machine.zone, MotionPathTriggerZone.after);
  });
}
