# Phase 8 acceptance gate

**Gate state: OPEN.** Phase 8 is unblocked now that Phase 6 parity and Phase 7 Carousel are complete.

## Goal

Add a production-style Helix scene that exercises 3D transforms and deterministic depth ordering without adding Helix-specific semantics to core composition.

## Existing foundation

- `MotionPathPatchTransform` already resolves `z`, `rotationX`, `rotationY`, `scaleZ`, and `perspective` into a Flutter-compatible 4x4 transform.
- The shared patch consumer already recognizes the 3D renderer keys.
- Spawn identity, reflow, front-most hit testing, and lifecycle teardown are covered by the Phase 4 and Phase 7 evidence.

## Next implementation slice

1. Add an explicit depth-order contract for spawned instances: sort by composed `z`, use stable authored order for equal depth, and keep hit testing front-most first.
2. Add a Helix scene builder that authors position, depth, rotation, scale, and perspective through normal tracks and patches.
3. Add trajectory assertions at representative progress points, including depth crossings and equal-depth ties.
4. Add widget coverage proving Matrix4 rendering and deterministic paint order across depth changes.
5. Record any intentional Flutter/JS differences and close the gate only after CI is green.

## Design decision

Use Flutter `Matrix4` at the renderer boundary. A pure-core projection utility is not justified yet because the existing renderer contract already carries the required 3D keys and no cross-platform projected-coordinate contract is needed.

## Exit criteria

- Helix is behaviorally equivalent at sampled points.
- Depth ordering is deterministic, including equal-depth ties.
- 3D transforms and perspective are covered by trajectory and widget tests.
- No Helix-specific patch interpretation exists in core.
- CI is green across all four jobs.
