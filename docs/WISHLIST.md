# Wishlist

Ideas worth building after the current demo and parity work. These are intentionally product-facing, not just renderer features.

## Renderer formalization

**Status:** Proposed  
**Priority:** Critical

Formalize one immutable frame source with composable Canvas, Widget, RenderObject, Overlay, and Headless renderers. Renderers work together in one scene but are chosen per entity. Add capability metadata, plugin compatibility diagnostics, shared-runtime lifecycle, Hero/overlay support, deterministic headless samples, and performance tooling.

**Review docs:** [`RENDERER_PRD.md`](RENDERER_PRD.md), [`RENDERER_IMPLEMENTATION_PLAN.md`](RENDERER_IMPLEMENTATION_PLAN.md), [`RENDERER_CAPABILITY_MATRIX.md`](RENDERER_CAPABILITY_MATRIX.md).

## MotionPathListView

**Status:** Proposed  
**Priority:** High  
**Problem:** Flutter's `ListView.builder` is excellent at lazy data rendering, but assumes every item belongs on a straight track.

**Proposal:** Add a sliver-native `MotionPathListView.builder` that preserves normal Flutter list behavior while placing visible children on an authored path. Use the typed API first, then add the advanced JSON/runtime adapter.

**Review document:** [MotionPathListView PRD and implementation plan](https://app.clickup.com/90141481884/docs/2kydkpww-474)

**Acceptance bar:** lazy construction, recycling, stable keys, accessibility, viewport-relative sampling, auto-rotation, variable-height support, pagination, reverse-scroll coverage, and no full-list rebuild on scroll.

## Product opportunities to validate

- Spatial onboarding and gesture education.
- Product discovery rails and editorial storytelling.
- Map, route, timeline, and journey interfaces.
- Data-rich dashboards where motion explains relationships.
- Creative portfolios, catalogs, and media browsing.
- Shared transitions between list, detail, canvas, and Hero overlay.
- Mixed-renderer game scenes and data-driven choreography.

These are hypotheses, not commitments. See [`USE_CASES_AND_PRODUCT_RATIONALE.md`](USE_CASES_AND_PRODUCT_RATIONALE.md).
