# Wishlist

Ideas worth building after the current demo and parity work.

## MotionPathListView

**Status:** Proposed  
**Priority:** High

A sliver-native `MotionPathListView.builder` that keeps lazy construction, recycling, semantics, stable keys, normal scrolling, and pagination while placing visible children on an authored motion system. Ship the typed path API first, then add a JSON/runtime adapter.

Review: [MotionPathListView PRD](https://app.clickup.com/90141481884/docs/2kydkpww-474).

## Renderer system

**Status:** Proposed  
**Priority:** Critical

Formalize one runtime frame consumed by Canvas, Widget, RenderObject, Overlay, and Headless renderers. Add stable entity identity, capability negotiation, fallback policy, mixed-renderer fan-out, and lifecycle-safe handoff. This is the foundation for `MotionPathHero.runtime`, path lists, dense scenes, and game-like integrations.

See [`RENDERER_PRD.md`](RENDERER_PRD.md), [`RENDERER_IMPLEMENTATION_PLAN.md`](RENDERER_IMPLEMENTATION_PLAN.md), and [`RENDERER_ROADMAP.md`](RENDERER_ROADMAP.md).

## Product opportunities to validate

- Spatial onboarding and gesture education.
- Product discovery rails and editorial storytelling.
- Maps, routes, journeys, and process timelines.
- Data storytelling and operational dashboards.
- Creative portfolios, media browsing, and immersive catalogs.
- Shared list-to-detail transitions and runtime-authored Hero flights.
- Game-like choreography: bullets, actors, quests, and scene transitions.

## Cross-cutting foundations

- Stable entity identity and renderer handoff.
- Input routing and hit testing across overlapping renderers.
- Semantics and reduced-motion policy.
- Asset lifecycle, cache budgets, and missing-resource recovery.
- Headless snapshots, recording, debug tooling, and visual inspection.
- Serialization versioning, migrations, hot reload, and deterministic replay.
- Fixed-step game-loop integration without a second scheduler.

See [`USE_CASES_AND_PRODUCT_RATIONALE.md`](USE_CASES_AND_PRODUCT_RATIONALE.md) for the product rationale.
