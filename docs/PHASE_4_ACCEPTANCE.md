# Phase 4 acceptance gate

**Gate state: READY TO CLOSE.**

Phase 4 dynamic children and spawn lifecycle are implemented and tested across
PRs #81 through #86. Close the phase when this documentation update is green
and merged.

## Completed scope

- Spawn and reflow are owned by `MotionPathSpawnController` with authored,
  fixed-duration easing rather than scroll scrub decay.
- Draining removes completed children without avalanching survivors, and
  reflow-induced completion waits for the next advance.
- Controller snapshots retain ascending settled-offset order for compatibility.
- `motionPathTopMostFirst()` provides deterministic front-most traversal with
  stable equal-offset ties.
- `MotionPathSpawnView` preserves keyed child identity, paints the front-most
  child last in the Stack, and supports an opt-in `onHit` callback.
- Shared ticker binding is the only frame source and detaches idempotently.
- Restart-wave behavior, disposal unwiring, and the Spiral example's redundant
  rebuild path are covered.

## Exit evidence

- Reflow, spawn, drain, lifecycle, ordering, host hit-test, widget, and shared
  ticker tests are green in the merged PR chain.
- No second ticker or competing `setState` path is required.
- Carousel and Helix remain sequenced after the next capability review.
