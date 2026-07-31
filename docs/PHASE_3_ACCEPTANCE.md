# Phase 3 acceptance gate

**Gate state: CLOSED. Phase 3 is complete.**

All Phase 3 implementation items are merged and green in PRs #73 through #80.
Carousel and Helix remain sequenced behind Phase 4.

## Completed scope

- Shared `MotionPathPatchView` consumes transform, opacity, color, visibility, filters, image frames, instances, CSS values, and supported 3D metadata.
- Child subtrees stay stable through `AnimatedBuilder.child` and fixed identity-safe wrappers.
- Per-track consumers, single composition per update, zero-listener gating, deep dirty checking, bounded filters, host-owned image cache lifecycle, performance coverage, and Spiral migration are complete.
- Renderer ownership is explicit through claimed and unsupported key sets.

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

## Exit evidence

CI is green and every checklist item is covered by merged PRs #73 through #80.
Phase 4 is the next active phase.
