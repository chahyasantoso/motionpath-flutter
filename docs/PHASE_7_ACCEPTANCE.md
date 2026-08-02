# Phase 7 acceptance gate

**Gate state: CLOSED.**

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
- PR #121 added host interaction coverage in the real demo: forward scroll, reverse scroll, re-entry, add, and per-card opacity read back from the shared scene rather than restated in the test.
- PR #122 derived the stage guide from `carouselPathPoints` via `carouselGuidePath()` and deleted the painter's own cubic literal, closing the demo audit.

## Renderer contract proof

Every Carousel visual now originates in a composed patch or the shared scene:

- Position, tangent rotation, anchor output, opacity, and scale come from composed patches (PRs #115, #118, #121).
- The authored path, opacity stops, and stagger live once in `example/lib/carousel_scene.dart` (PRs #119, #120).
- The stage guide is drawn from those same authored points (PR #122).
- No demo-local path, progress, or visual interpolation math remains. The only host-side arithmetic is the scroll-offset window that maps scroll position to timeline progress, which is scrubbing input, not scene definition.

## Intentional Flutter differences

Recorded in full in `docs/COMPATIBILITY.md`. Summary:

- Carousel does not use drain semantics; `drainOnComplete` stays Spiral-only.
- Card identity is anchored with a scoped per-card `GlobalKey`.
- Scroll progress is owned by a Flutter `ScrollPosition`, not a JS smooth-scroll library.
- Host tests drive `ScrollPosition` directly because gesture touch slop is a Flutter framework artifact with no reference analogue.
- Authored end-boundary opacity evidence stays at the scene and geometry level because the demo's stage leaves the viewport before a card reaches progress 1.

The eased-overshoot clamp is **not** on this list. It remains an open Phase 6 decision in `docs/PHASE_6_ACCEPTANCE.md`.

## Closeout checklist

- Demo consumes the shared scene definition. Done, PR #120.
- Interaction coverage in the demo host is green. Done, PR #121.
- Representative trajectory and geometry evidence is green. Done, PRs #118 and #119.
- Demo audit leaves no scene literal outside the shared definition. Done, PR #122.
- Intentional differences are documented. Done, see above and `docs/COMPATIBILITY.md`.

Phase 7 is **Complete**. Regressions reopen the gate; new Carousel work does not.
