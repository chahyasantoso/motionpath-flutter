# Phase 8 acceptance gate

**Gate state: CLOSED.** Phase 8 is complete on `main` after PRs #124, #125, and #126 merged green.

## Goal

Add a production-style Helix scene that exercises 3D transforms and deterministic depth ordering without adding Helix-specific semantics to core composition.

## Completed evidence on `main`

- PR #124 adds the generic depth-order contract: composed `z`/`translateZ` controls back-to-front paint order, missing depth falls back to offset order, equal-depth items preserve authored order, and hit testing traverses front-most first.
- PR #124 applies composed 3D transforms through Flutter `Matrix4` in the generic spawn host and covers the host with widget tests.
- PR #125 adds the shared Helix scene builder with authored x/y/z, Y rotation, scale, and perspective values, plus sampled trajectory assertions.
- PR #126 adds the real Helix demo host, mounts all authored cards through `MotionPathSpawnView`, and covers Matrix4 rendering in the example widget suite.

## Exit criteria

- Helix is behaviorally equivalent at sampled points. Done, PR #125.
- Depth ordering is deterministic, including equal-depth ties. Done, PR #124.
- 3D transforms and perspective are covered by trajectory and widget tests. Done, PRs #124 through #126.
- No Helix-specific patch interpretation exists in core. Done, PRs #124 through #126 use the generic spawn host and ordinary track properties.
- CI is green across all four jobs. Done, PR #126.

## Design decision

Use Flutter `Matrix4` at the renderer boundary. A pure-core projection utility is not justified because the existing renderer contract already carries the required 3D keys and no cross-platform projected-coordinate contract is needed.

## Intentional differences

- Depth ordering is implemented by the Flutter host because `Stack` has no CSS-like automatic `z-index`; composed `z` remains renderer-neutral.
- The Helix demo uses Flutter `Matrix4` rather than reproducing a browser projection pipeline. This preserves the observable transform contract without claiming source parity.

Phase 8 is **Complete**. Regressions reopen the gate; new Helix work does not.
