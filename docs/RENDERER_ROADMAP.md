# Renderer system roadmap

## R0: stabilize the contract

- Define immutable frame, entity identity, binding lifecycle, capabilities, diagnostics, and fallback policy.
- Inventory and map existing painter, widget, spawn, transform, filter, image, depth, and hit-test consumers.

Exit criteria: the same runtime frame can be described and validated without knowing the target renderer.

## R1: multi-renderer fan-out

- Fan one runtime frame to multiple renderer bindings.
- Add interest filtering and dirty entity updates.
- Formalize CanvasRenderer and WidgetRenderer around the current implementations.

Exit criteria: one scene uses Canvas for dense background entities and Widget for interactive entities with one scheduler.

## R2: RenderObject and path-list foundation

- Add RenderObjectRenderer.
- Build the `MotionPathListView` on slivers and render-time updates.
- Add layout-aware hit testing and repaint isolation.

Exit criteria: 1000 logical items remain lazy and scrolling does not rebuild the whole list.

## R3: Overlay and Hero

- Add OverlayRenderer.
- Add `MotionPathHero.runtime` with full plugin composition.
- Test route push/pop, reverse gestures, cancellation, and handoff.

Exit criteria: a list item can promote into a runtime-authored Hero flight and return without state or resource leaks.

## R4: headless parity and tooling

- Add headless snapshots and renderer parity tests.
- Add capability reports, diagnostics, frame recording, and debug overlays.

Exit criteria: a motion project can be validated and sampled without Flutter, then compared with Flutter output.

## R5: production and game readiness

- Add asset lifecycle contracts, reduced-motion policies, fixed-step/game-loop input, pause/background behavior, and memory budgets.
- Add deterministic replay hooks and optional network-safe frame sampling.
- Publish renderer integration guides and example vertical slices.

Exit criteria: mixed-renderer applications can ship with documented budgets, recovery behavior, and stable lifecycle semantics.

## What else the system still needs

Renderer formalization is necessary but not sufficient. The next gaps are:

1. Scene/entity identity and handoff semantics.
2. Capability negotiation and actionable diagnostics.
3. Hit testing and input routing across overlapping renderers.
4. Accessibility semantics and reduced-motion behavior.
5. Asset/image/filter resource lifecycle and cache budgets.
6. Deterministic fixed-step input and replay for game-like use cases.
7. Debug tooling, frame inspection, recording, and visual authoring.
8. Serialization/versioning/migration guarantees.
9. Error recovery, hot reload, and route/background lifecycle behavior.
10. Performance budgets and device-specific profiling.

These should be treated as platform foundations, not scattered feature requests.
