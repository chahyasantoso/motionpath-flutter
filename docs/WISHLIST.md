# Wishlist

Ideas worth building after the current demo and parity work. These are intentionally product-facing, not just renderer features.

## MotionPathListView

**Status:** Proposed  
**Priority:** High  
**Problem:** Flutter's `ListView.builder` is excellent at lazy data rendering, but it assumes every item belongs on a straight vertical or horizontal track. Teams that want spatial, editorial, playful, or exploratory interfaces have to build a second scene layer, hand-write scroll math, or abandon list semantics and recycling.

**Proposal:** Add a sliver-native `MotionPathListView.builder` that keeps normal Flutter list behavior while placing visible children on an authored path. It should support a typed path API first, with an advanced JSON/runtime adapter later.

**Why it belongs here:** This is the clearest productization of the existing system. The repository already has normalized scroll progress, path sampling, renderer-neutral patches, stable child rendering, depth, and hit-testing work. The widget turns those engine capabilities into a reusable primitive rather than another one-off demo.

**Review document:** [MotionPathListView PRD and implementation plan](https://app.clickup.com/90141481884/docs/2kydkpww-474)

**Acceptance bar:** lazy builder semantics, recycling, stable keys, normal scrolling and accessibility, viewport-relative path sampling, auto-rotation, fixed and variable-height support, pagination hooks, reverse-scroll coverage, and no full-list rebuild on scroll.

## Product opportunities to validate

- Spatial onboarding and gesture education.
- Product discovery rails and editorial storytelling.
- Map, route, timeline, and journey interfaces.
- Data-rich dashboards where motion explains relationships or change.
- Creative portfolios, catalogs, and media browsing.
- Reusable transition choreography between list, detail, and canvas scenes.

These are hypotheses, not commitments. The companion research document explains the user problems, evidence, fit, risks, and recommended order.

See [`docs/USE_CASES_AND_PRODUCT_RATIONALE.md`](USE_CASES_AND_PRODUCT_RATIONALE.md).
