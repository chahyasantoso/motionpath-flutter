# Phase 8 acceptance gate

**Gate state: OPEN.** Phase 8 is unblocked now that Phase 6 parity and Phase 7 Carousel are complete.

## Goal

Add a production-style Helix scene that exercises 3D transforms and deterministic depth ordering without adding Helix-specific semantics to core composition.

## Completed evidence on `main`

- PR #124 adds the generic depth-order contract: composed `z`/`translateZ` controls back-to-front paint order, missing depth falls back to offset order, equal-depth items preserve authored order, and hit testing traverses front-most first.
- PR #124 applies composed 3D transforms through Flutter `Matrix4` in the generic spawn host and covers the host with widget tests.
- PR #125 adds the shared Helix scene builder with authored x/y/z, Y rotation, scale, and perspective values, plus sampled trajectory assertions.

## Next implementation slice

1. Add a real Helix demo host that renders the shared scene through `MotionPathSpawnView`.
2. Add widget coverage for the Helix host across depth crossings, perspective, and stable equal-depth ordering.
3. Record any intentional Flutter/JS differences and close the gate only after CI is green.

## Design decision

Use Flutter `Matrix4` at the renderer boundary. A pure-core projection utility is not justified yet because the existing renderer contract already carries the required 3D keys and no cross-platform projected-coordinate contract is needed.

## Exit criteria

- Helix is behaviorally equivalent at sampled points.
- Depth ordering is deterministic, including equal-depth ties.
- 3D transforms and perspective are covered by trajectory and widget tests.
- No Helix-specific patch interpretation exists in core.
- CI is green across all four jobs.
