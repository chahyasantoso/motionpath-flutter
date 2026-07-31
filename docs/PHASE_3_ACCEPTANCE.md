# Phase 3 acceptance gate

Phase 3 is active after the green Phase 2 merge.

## Completed in current slice

- `MotionPathPatchView` now consumes shared color, visibility, CSS variable, image-frame, and spawned-instance payload adapters.
- Existing transform, opacity, and blur handling remains covered.
- Child subtree reuse remains covered by `AnimatedBuilder.child`.

## Remaining required implementation

- Shared transform resolver for z, perspective, and supported 3D values.
- Explicit unsupported-key policy.
- Image cache and disposal strategy at the host boundary.
- Dirty checking for unchanged patches.
- Painter and performance coverage for the complete contract.
- Full demo migration away from local patch interpretation.

## Exit rule

Phase 3 is complete only when every item has implementation and tests, CI is green, this gate is marked complete, and the PR is merged into `main`.
