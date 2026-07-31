/// Where a sampled value sits relative to its authored window.
enum MotionPathTriggerZone {
  /// Before the window's start.
  before,

  /// Within the window. Both endpoints count as inside.
  inside,

  /// Past the window's end.
  after,
}

/// One boundary crossing a host can react to.
///
/// Names follow the authored v4 contract: [enter] and [leave] describe forward
/// travel, [enterBack] and [leaveBack] describe reverse travel.
enum MotionPathToggleAction {
  /// Forward travel moved into the window.
  enter,

  /// Forward travel moved past the window.
  leave,

  /// Reverse travel moved back into the window.
  enterBack,

  /// Reverse travel moved back out ahead of the window.
  leaveBack,
}

/// Turns a stream of sampled positions into ordered boundary crossings.
///
/// This is deliberately scroll-agnostic. It takes a plain number, so a scroll
/// offset, a timeline position, or a test harness all drive the same edge
/// detection, and nothing here schedules a frame or touches a playhead.
///
/// The first [update] after construction or [reset] only seeds the current
/// zone and reports nothing. Attaching to a scroll position already past a
/// window must not replay an entry that never happened, and neither must
/// reattaching after a route change.
class MotionPathToggleStateMachine {
  /// Creates an unseeded machine.
  ///
  /// [onAction] receives every crossing in travel order. The zone is already
  /// updated before the first callback runs, so a callback that samples again
  /// re-enters safely.
  MotionPathToggleStateMachine({this.onAction});

  /// Called once per crossing, in travel order.
  final void Function(MotionPathToggleAction action)? onAction;

  MotionPathTriggerZone? _zone;

  /// Current zone, or null while the machine is unseeded.
  MotionPathTriggerZone? get zone => _zone;

  /// Whether a first sample has been observed.
  bool get isSeeded => _zone != null;

  /// Throws when `[start, end]` is not a usable window.
  ///
  /// An inverted window is an authoring error, not a degenerate case worth
  /// guessing at: it would otherwise pin progress to a constant and never
  /// report a crossing.
  static void validateWindow(double start, double end) {
    if (!start.isFinite) {
      throw ArgumentError.value(start, 'start', 'must be finite');
    }
    if (!end.isFinite) {
      throw ArgumentError.value(end, 'end', 'must be finite');
    }
    if (end < start) {
      throw ArgumentError.value(
        end,
        'end',
        'must be greater than or equal to start ($start)',
      );
    }
  }

  /// Zone of [value] within `[start, end]`.
  ///
  /// A zero-span window keeps a single-point inside zone at `start`, which
  /// keeps a point trigger reporting a crossing rather than silently never
  /// firing.
  static MotionPathTriggerZone zoneFor({
    required double value,
    required double start,
    required double end,
  }) {
    validateWindow(start, end);
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
    if (value < start) return MotionPathTriggerZone.before;
    if (value > end) return MotionPathTriggerZone.after;
    return MotionPathTriggerZone.inside;
  }

  /// Crossings produced by moving from [previous] to [next].
  ///
  /// A sample can skip the window entirely when a scroll jumps, so a
  /// before/after transition reports both of its crossings rather than
  /// swallowing the one that had no frame of its own.
  static List<MotionPathToggleAction> actionsBetween(
    MotionPathTriggerZone previous,
    MotionPathTriggerZone next,
  ) =>
      switch ((previous, next)) {
        (MotionPathTriggerZone.before, MotionPathTriggerZone.before) =>
          const <MotionPathToggleAction>[],
        (MotionPathTriggerZone.before, MotionPathTriggerZone.inside) =>
          const <MotionPathToggleAction>[MotionPathToggleAction.enter],
        (MotionPathTriggerZone.before, MotionPathTriggerZone.after) =>
          const <MotionPathToggleAction>[
            MotionPathToggleAction.enter,
            MotionPathToggleAction.leave,
          ],
        (MotionPathTriggerZone.inside, MotionPathTriggerZone.before) =>
          const <MotionPathToggleAction>[MotionPathToggleAction.leaveBack],
        (MotionPathTriggerZone.inside, MotionPathTriggerZone.inside) =>
          const <MotionPathToggleAction>[],
        (MotionPathTriggerZone.inside, MotionPathTriggerZone.after) =>
          const <MotionPathToggleAction>[MotionPathToggleAction.leave],
        (MotionPathTriggerZone.after, MotionPathTriggerZone.before) =>
          const <MotionPathToggleAction>[
            MotionPathToggleAction.enterBack,
            MotionPathToggleAction.leaveBack,
          ],
        (MotionPathTriggerZone.after, MotionPathTriggerZone.inside) =>
          const <MotionPathToggleAction>[MotionPathToggleAction.enterBack],
        (MotionPathTriggerZone.after, MotionPathTriggerZone.after) =>
          const <MotionPathToggleAction>[],
      };

  /// Records [next] and reports the crossings it caused.
  List<MotionPathToggleAction> update(MotionPathTriggerZone next) {
    final MotionPathTriggerZone? previous = _zone;
    _zone = next;
    if (previous == null) return const <MotionPathToggleAction>[];
    final List<MotionPathToggleAction> actions =
        actionsBetween(previous, next);
    final void Function(MotionPathToggleAction action)? callback = onAction;
    if (callback != null) {
      for (final MotionPathToggleAction action in actions) {
        callback(action);
      }
    }
    return actions;
  }

  /// Resolves [value] against `[start, end]` and applies it.
  List<MotionPathToggleAction> updateForValue({
    required double value,
    required double start,
    required double end,
  }) =>
      update(zoneFor(value: value, start: start, end: end));

  /// Drops the seeded zone so the next sample seeds silently again.
  void reset() {
    _zone = null;
  }
}
