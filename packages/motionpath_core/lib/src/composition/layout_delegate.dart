import 'package:meta/meta.dart';

/// A child whose settled logical position a layout delegate can read.
///
/// A delegate never mutates a child and never touches a playhead. It reads
/// offsets and returns numbers or plans, and the owning track applies them.
/// That keeps placement policy testable without a runtime track, a host, or a
/// frame source.
abstract interface class MotionPathLayoutChild {
  /// Settled logical offset of this child, in seconds.
  ///
  /// This is the source of truth for placement, never a live playhead. A
  /// playhead is actively animating during an in-flight reflow and would give
  /// unstable targets.
  double get currentOffset;
}

/// One planned reflow: move [child] to [offset].
@immutable
class MotionPathReflowTarget {
  /// Creates a reflow target.
  const MotionPathReflowTarget({required this.child, required this.offset});

  /// Child to move.
  final MotionPathLayoutChild child;

  /// New settled offset, in seconds.
  final double offset;

  @override
  bool operator ==(Object other) =>
      other is MotionPathReflowTarget &&
      identical(other.child, child) &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(identityHashCode(child), offset);

  @override
  String toString() => 'MotionPathReflowTarget(offset: $offset)';
}

/// Contract for pluggable child placement policy on track composition.
///
/// An implementation decides where a new child goes ([computeSpawnOffset]) and
/// whether removal reflows the surviving siblings ([computeReflow]). The track
/// owns the mechanics; the delegate owns the policy.
///
/// Stateless implementations are safe to share across every track. A stateful
/// implementation must be constructed per parent track, because [computeReflow]
/// is not guaranteed to be free of side effects.
abstract class MotionPathLayoutDelegate {
  /// Allows const subclasses.
  const MotionPathLayoutDelegate();

  /// Offset for a new child, given the live [children] before it is added.
  double computeSpawnOffset(
    List<MotionPathLayoutChild> children, {
    double stagger = 0,
  });

  /// Reflow plan for the survivors of removing [removedChild].
  ///
  /// [children] is the live list before the removal, so it still contains
  /// [removedChild]. Returns an empty list when no reflow is needed.
  List<MotionPathReflowTarget> computeReflow(
    List<MotionPathLayoutChild> children,
    MotionPathLayoutChild removedChild, {
    double stagger = 0,
  });
}

/// Default placement policy: append after the frontmost child, close gaps on
/// removal.
///
/// Placement is derived from actual current sibling state rather than a counter
/// walked from a fixed origin. A counter fixes live-count plateauing under
/// churn but goes stale the moment a reflow shifts the existing chain, which
/// leaves a permanent extra stagger-width gap between the old chain and
/// everything spawned after it. Anchoring to the real frontmost offset is
/// immune to both failure modes and needs no reset bookkeeping: an empty chain
/// naturally resolves to zero.
class MotionPathGaplessLayoutDelegate extends MotionPathLayoutDelegate {
  /// Creates the gapless policy. Stateless, so one instance is enough.
  const MotionPathGaplessLayoutDelegate();

  @override
  double computeSpawnOffset(
    List<MotionPathLayoutChild> children, {
    double stagger = 0,
  }) {
    double frontmost = -stagger;
    for (final MotionPathLayoutChild child in children) {
      if (child.currentOffset > frontmost) {
        frontmost = child.currentOffset;
      }
    }
    return frontmost + stagger;
  }

  @override
  List<MotionPathReflowTarget> computeReflow(
    List<MotionPathLayoutChild> children,
    MotionPathLayoutChild removedChild, {
    double stagger = 0,
  }) {
    final List<MotionPathLayoutChild> ordered = orderByOffset(children);
    final int removedRank = rankOf(ordered, removedChild);

    // Cascade only when removing from the middle of the chain. Removing the
    // frontmost child never creates a gap: it is the leading edge, and the
    // next child naturally becomes the new leader. Cascading a rank-0 removal
    // would shift every survivor earlier, which can push children past
    // completion and trigger an avalanche of instant completions during a
    // natural drain. A child that is not in the chain has rank -1 and is also
    // ignored.
    if (removedRank <= 0) {
      return const <MotionPathReflowTarget>[];
    }

    return List<MotionPathReflowTarget>.unmodifiable(
      <MotionPathReflowTarget>[
        for (int index = removedRank + 1; index < ordered.length; index++)
          MotionPathReflowTarget(
            child: ordered[index],
            offset: ordered[index - 1].currentOffset,
          ),
      ],
    );
  }

  /// Orders [children] by settled offset, stably.
  ///
  /// Reflow must walk children in actual timeline-position order, not insertion
  /// order, because a manually staggered child can land anywhere relative to
  /// its auto-placed siblings. Ties keep insertion order so an equal-offset
  /// chain still reflows deterministically. This is an insertion pass rather
  /// than `List.sort` because `List.sort` is not stable, and a child chain is
  /// far too small for the difference in cost to matter.
  @protected
  List<MotionPathLayoutChild> orderByOffset(
    List<MotionPathLayoutChild> children,
  ) {
    final List<MotionPathLayoutChild> ordered = <MotionPathLayoutChild>[];
    for (final MotionPathLayoutChild child in children) {
      int slot = ordered.length;
      while (slot > 0 && ordered[slot - 1].currentOffset > child.currentOffset) {
        slot--;
      }
      ordered.insert(slot, child);
    }
    return ordered;
  }

  /// Identity rank of [child] within an already ordered chain, or -1.
  ///
  /// Identity, not equality: two distinct children can legitimately share a
  /// settled offset.
  @protected
  int rankOf(
    List<MotionPathLayoutChild> ordered,
    MotionPathLayoutChild child,
  ) {
    for (int index = 0; index < ordered.length; index++) {
      if (identical(ordered[index], child)) {
        return index;
      }
    }
    return -1;
  }
}

/// Same spawn placement as [MotionPathGaplessLayoutDelegate], but removals
/// never reflow.
///
/// Survivors keep their settled offset exactly as it was and the gap a removed
/// child leaves is never closed. Because spawn placement still anchors to the
/// frontmost offset, and offsets never decrease under this policy, the parent's
/// used span grows monotonically with total spawns over a session: it does not
/// shrink back as children are removed. That is correct when items should stay
/// where they visually landed, and wrong for long-running high-churn scenes.
/// Use [MotionPathGaplessLayoutDelegate] when the span must stay bounded.
class MotionPathStaticLayoutDelegate extends MotionPathGaplessLayoutDelegate {
  /// Creates the static policy.
  const MotionPathStaticLayoutDelegate();

  @override
  List<MotionPathReflowTarget> computeReflow(
    List<MotionPathLayoutChild> children,
    MotionPathLayoutChild removedChild, {
    double stagger = 0,
  }) =>
      const <MotionPathReflowTarget>[];
}

/// Shared stateless gapless policy, used when a track declares none.
const MotionPathGaplessLayoutDelegate kGaplessLayoutDelegate =
    MotionPathGaplessLayoutDelegate();

/// Shared stateless static policy.
const MotionPathStaticLayoutDelegate kStaticLayoutDelegate =
    MotionPathStaticLayoutDelegate();
