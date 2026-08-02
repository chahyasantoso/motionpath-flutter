# Phase 7 acceptance gate

**Gate state: OPEN.**

Phase 7 proves the shared renderer can support a real production-style scene without Carousel-specific engine math.

## Completed evidence on `main`

- PR #91 fixed the authored path payload required by Carousel.
- PR #92 added tangent-aligned `autoRotate`.
- PR #93 added the scroll-driven Carousel example with dynamic children, stagger, opacity, transforms, add/remove interaction, and front-most hit testing.
- PR #94 added widget coverage for page mount, rendered cards, and real ListView scrubbing.
- PR #114 added reverse-scroll coverage, proving card identity, settled offsets, and child playheads survive reverse scrubbing.
- PR #115 added stable card-subtree coverage and fixed the spawn view to cache each expensive child by instance id. The implementation uses a per-card `GlobalKey` as the scoped identity anchor; this is deliberate, not a blanket recommendation. A future render-host or AnimatedWidget design could avoid GlobalKey overhead, but changing that architecture during Carousel closeout would be needless risk.

## Remaining work

### P0: renderer contract proof

- Confirm every Carousel visual comes from composed patches: x/y, rotation, opacity, scale, anchor, and any image payload.
- Remove any remaining demo-local path, progress, or visual interpolation math.
- Add widget assertions for transformed position, opacity boundaries, anchor output, and child identity across scroll updates.
- Prove expensive card subtrees remain stable while patches update. PR #115 covers the card subtree identity contract.

### P0: dynamic lifecycle proof

- Cover add-card identity and stable keys.
- Cover tap-to-remove selecting the front-most card when cards overlap.
- Cover mid-chain removal and reflow without teleporting survivors.
- Cover teardown while cards are mounted and after the scroll host is disposed.
- Cover empty-carousel recovery and adding a card after the list drains. Drain behavior belongs to Spiral-style scenes, not the Carousel contract, so it is intentionally not part of Carousel coverage.

### P1: scene parity

- Keep the Flutter scene schema aligned with the JS `dynamicCarouselScene`: path points, path stops, autoRotate, opacity stops, stagger, and stagger transition.
- Add a shared fixture or builder so the demo is not maintaining a second hand-copied scene definition.
- Add interaction coverage for scroll forward, reverse, add, remove, and re-entry.

### P1: visual regression

- Add a stable widget golden or sampled geometry assertions for representative progress values: 0, 0.15, 0.5, 0.85, and 1.
- Assert cards disappear at the authored opacity/path boundaries.
- Assert ordering is deterministic for equal offsets.

## Closeout checklist

Phase 7 can move to **Complete** when:

- The Carousel uses shared patch consumers only, with no duplicated engine math.
- Widget tests cover mount, scroll, reverse scroll, add, remove, overlap hit testing, reflow, and teardown.
- Representative trajectory or golden coverage is green.
- The JS scene mapping is recorded and intentional differences are documented.
- The Phase 7 row cites the final implementation and coverage PRs plus this document.
