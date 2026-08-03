# MotionPath Flutter engine roadmap

## Phases 0 through 6: engine foundation and release

Phases 0 through 6 remain the foundation: package boundaries, contract validation, graph compilation, pure runtime, Flutter scheduling/renderers, production hardening, and package release. Their original exit criteria remain unchanged.

## Phase 7: product primitives

- Build `MotionPathListView.builder` on top of `CustomScrollView` and sliver-native lazy construction.
- Extract or share the canonical path sampler with the existing `path` plugin.
- Preserve controller behavior, recycling, semantics, reverse scroll, pagination, and stable keys.
- Validate gesture education and a data-backed journey/process timeline.

See [`docs/WISHLIST.md`](WISHLIST.md) and [the MotionPathListView PRD](https://app.clickup.com/90141481884/docs/2kydkpww-474).

## Phase 8: renderer system

- Implement the immutable frame and stable entity identity contracts.
- Formalize Canvas, Widget, RenderObject, Overlay, and Headless renderer bindings.
- Add capability negotiation, fallback policy, diagnostics, and interest filtering.
- Support mixed-renderer scenes from one runtime frame.
- Add `MotionPathHero.runtime` using Flutter Hero pairing and OverlayRenderer ownership.

Exit criteria: Canvas and Widget renderers consume one frame together, RenderObject supports the path list, and Overlay supports a plugin-authored Hero flight without lifecycle leaks.

## Phase 9: system hardening

- Add semantics, reduced motion, hit testing/input routing, asset lifecycle, cache budgets, and background/route recovery.
- Add headless snapshots, frame recording, debug inspection, and cross-renderer parity tests.
- Add serialization versioning, migrations, hot reload behavior, fixed-step game-loop input, deterministic replay, and device profiling.

Exit criteria: the system is safe to use as a reusable interaction layer in production apps and small game-like experiences, with documented failure and performance behavior.

## Recommended order

Do not add more showcase demos before the contracts are stronger. Build in this order: renderer contract, multi-renderer fan-out, RenderObject path list, Overlay/Hero, headless parity, then cross-cutting hardening. The boring infrastructure is what makes the wild ideas shippable.
