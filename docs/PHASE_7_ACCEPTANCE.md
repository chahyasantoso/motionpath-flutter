# Phase 7 acceptance gate

**Gate state: OPEN.**

Phase 7 proves the shared renderer can support a real production-style scene without Carousel-specific engine math.

## Completed evidence on `main`

- PR #91 fixed the authored path payload required by Carousel.
- PR #92 added tangent-aligned `autoRotate`.
- PR #93 added the scroll-driven Carousel example with dynamic children, stagger, opacity, transforms, add/remove interaction, and front-most hit testing.
- PR #94 added widget coverage for page mount, rendered cards, and real ListView scrubbing.
- PR #114 added reverse-scroll coverage, proving card identity, settled offsets, and child playheads survive reverse scrubbing.
- PR #115 added stable card-subtree coverage and fixed the spawn view to cache each expensive child by instance id. The implementation uses a per-card `GlobalKey` as a scoped identity anchor; a stable host/render-object design could avoid that overhead, but changing architecture during closeout is deliberately deferred.
- PR #116 added overlapping-card front-most hit testing and mid-chain removal/reflow coverage with no survivor teleport.
- PR #117 added Carousel teardown coverage for scroll/ticker binding disposal and controller hook cleanup.
- PR #118 added representative geometry assertions at 0, 0.15, 0.5, 0.85, and 1 for composed position, tangent rotation, center anchor output, opacity, scale, and deterministic patches.
- PR #119 added the shared executable scene contract for the five-point path, quadratic controls, `autoRotate`, opacity stops, and 0.1 stagger.
- PR #120 moved the authored scene into `example/lib/carousel_scene.dart` and made the demo consume `carouselCardTrack` and `carouselCardStagger`, removing the second hand-copied scene definition.

## Remaining work

### P0: renderer contract proof

- Confirm every Carousel visual comes from composed patches: x/y, rotation, opacity, scale, anchor, and any image payload.
- Remove any remaining demo-local path, progress, or visual interpolation math.
- Add widget assertions for transformed position, opacity boundaries, anchor output, and child identity across scroll updates. Geometry and subtree identity are covered by PRs #115 and #118; the demo audit remains.

### P1: scene parity and interaction

- Add widget interaction coverage for forward scroll, reverse scroll, add, remove, and re-entry in the real demo host.
- Record intentional Flutter/JS scene differences.

### P1: visual regression

- Keep the representative sampled geometry assertions green. A golden is optional; deterministic patch assertions are the current regression strategy.
- Assert host card visibility tracks the authored opacity stops. Note the demo's scroll range: a card only reaches the authored end boundary after the stage has left the viewport, so end-boundary evidence stays at the scene and geometry level while the host covers the start boundary and the fade ramps.

## Closeout checklist

Phase 7 can move to **Complete** when the interaction coverage in the demo host is green, representative trajectory evidence is green, and intentional differences are documented. The demo now consumes the shared scene definition.
