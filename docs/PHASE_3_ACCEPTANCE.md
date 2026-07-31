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
| z, perspective, and 3D transform resolver | Done | PR #76 shared matrix for widget and painter paths. |
| Explicit unsupported-key behavior | Done | This slice exposes claimed renderer keys, an explicit unsupported set, and tests that unknown plugin keys are ignored rather than falsely claimed. |
| Image resolution cache and disposal strategy | Done | PR #77 host-owned generic frame cache, explicit eviction, and idempotent disposal. |
| Performance tests | Done | PR #78 pumps 250 updates and asserts the supplied child subtree never rebuilds. |
| Demo migration off local engine math | Done | PR #79 renders Spiral balls through `MotionPathPatchView`; the guide remains presentation-only. |

## Renderer key policy

The generic Flutter renderer claims the keys listed in
`motionPathClaimedRendererKeys`. The unsupported set is explicit and currently
empty, so every claimed key is consumed. Unknown plugin-owned keys are ignored
by the generic renderer and may be handled by host builders. A future claimed
key must be added to the claimed or unsupported set and covered by tests before
it lands.

## Image ownership policy

`image` values are immutable frame identifiers only. Hosts may use
`MotionPathImageFrameCache<T>` to resolve identifiers into decoded images or
other resources. The host supplies the loader and disposer, controls eviction,
and must dispose the cache when the owning scene is torn down.

## Exit rule

Phase 3 is complete only when every item has implementation and tests, CI is green, the implementation plan and phase status are updated, and the PR is merged into `main`.
