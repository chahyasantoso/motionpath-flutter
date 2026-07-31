# Phase 3 acceptance gate

Phase 3 is active after the green Phase 2 merge.

## Required implementation

- Make `MotionPathPatchView` consume the shared patch contract for transform, opacity, color, visibility, filters, image frames, instances, CSS values, and supported 3D metadata.
- Keep child subtrees stable with `AnimatedBuilder.child` or a repaint-driven painter path.
- Define unsupported-key behavior and a shared transform resolver for translation, rotation, scale, z, perspective, and supported 3D values.
- Keep image loading, caching, and disposal outside core.
- Add dirty checking for unchanged patches.
- Add widget, painter, consumer, and performance tests.

## Compatibility constraints

- Do not change core animation semantics.
- Do not make demos reinterpret authored keys independently.
- Preserve the Walker whole-graph path.
- Do not begin Carousel or Helix until this gate is complete.

## Exit rule

Phase 3 is complete only when every item has implementation and tests, CI is green, the implementation plan and phase status are updated, and the PR is merged into `main`.
