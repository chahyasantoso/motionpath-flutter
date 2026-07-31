# Phase 3 acceptance gate

Phase 3 is active after the green Phase 2 merge.

**Gate state: OPEN. Phase 3 is not complete.** Carousel and Helix remain blocked.

## Required implementation

- Make `MotionPathPatchView` consume the shared patch contract for transform, opacity, color, visibility, filters, image frames, instances, CSS values, and supported 3D metadata.
- Keep child subtrees stable with `AnimatedBuilder.child` or a repaint-driven painter path.
- Define unsupported-key behavior and a shared transform resolver for translation, rotation, scale, z, perspective, and supported 3D values.
- Keep image loading, caching, and disposal outside core.
- Add dirty checking so unchanged patches do not trigger unnecessary paint work.
- Add widget, painter, consumer, and performance tests.

## Compatibility constraints

- Do not change core animation semantics.
- Do not make demos reinterpret authored keys independently.
- Preserve the Walker whole-graph path.
- Do not begin Carousel or Helix until this gate is complete.

## Checklist

| Item | State | Evidence |
|---|---|---|
| Transform, opacity, blur consumption | Done | `MotionPathPatchView`, `MotionPathPatchTransform`, renderer tests. |
| Color and visibility consumption | Done | PR #73; unconditional identity-safe wrappers. |
| Image frame, CSS variable, and instance payloads | Done | PR #73 host-owned builders and consumers. |
| Stable child subtree | Done | `AnimatedBuilder.child` and fixed wrapper chain. |
| Dirty checking | Done | Deep patch equality in controller and painter. |
| Interest-scoped per-track consumers | Done | PR #74 `trackPatch()` and whole-graph fallback. |
| One composition per update | Done | PR #74 separates advancement from composition. |
| Zero-listener tick gating | Done | PR #74 gates frame-driven composition. |
| Bounded filters and invalid-sigma tests | Done | PR #75 bounded blur consumer and tests. |
| z, perspective, and 3D transform resolver | Done | This slice resolves z, perspective, scaleZ, rotateX, rotateY, and rotation into one matrix for both widget and painter paths. |
| Explicit unsupported-key behavior | Partial | Unknown keys are ignored and renderer policy is documented; claimed-but-unsupported reporting is still open. |
| Image resolution cache and disposal strategy | **Open** | The host receives a raw frame payload. No cache or disposal contract. |
| Performance tests | **Open** | No renderer benchmark covering rebuilds, allocations, or paint invalidations. |
| Demo migration off local engine math | **Open** | Spiral still recomputes path position, color, visibility, and reflow locally. |

## Renderer key policy

Unknown patch keys are ignored at the Flutter boundary. Keys claimed by a renderer contract must either be consumed or listed as explicitly unsupported and covered by tests. Plugin-owned payloads pass to host builders.

## Exit rule

Phase 3 is complete only when every item has implementation and tests, CI is green, the implementation plan and phase status are updated, and the PR is merged into `main`.
