# Renderer system implementation plan

## Phase 1: contract and inventory

- Inventory current painters, patch consumers, spawn views, transforms, filters, image cache, hit testing, and lifecycle APIs.
- Define `MotionPathFrame`, `MotionPathEntityId`, `MotionPathRendererBinding`, `MotionPathRendererCapabilities`, and renderer diagnostics.
- Define output ownership: runtime patches are immutable; renderer state is target-local.
- Add contract tests for stable entity identity, patch immutability, ordering, and unsupported fields.

## Phase 2: shared frame distribution

- Add a frame publisher that can fan out one composed frame to multiple renderer bindings.
- Add interest filtering so each renderer receives only the entity IDs and fields it needs.
- Keep batching and dirty-node semantics from `GraphPublisher`.
- Define attach, detach, replace, and dispose behavior as idempotent operations.

## Phase 3: capability registry

- Extend plugin metadata with renderer capability requirements and fallback policy.
- Validate a scene before mount when a plugin cannot be consumed by its selected renderer.
- Add diagnostics for unsupported output, missing image providers, invalid filter bounds, and conflicting ownership.
- Document the capability matrix and version it with the public contract.

## Phase 4: formalize existing Flutter renderers

- Adapt existing patch views and spawn views to the binding contract.
- Formalize `CanvasRenderer` around `CustomPainter` and repaint `Listenable` behavior.
- Formalize `WidgetRenderer` around stable keyed subtrees and patch consumers.
- Add `RenderObjectRenderer` for layout-aware transforms, path lists, repaint isolation, and hit testing.
- Add renderer-level performance counters without putting instrumentation in hot paths by default.

## Phase 5: Overlay and Hero

- Implement `OverlayRenderer` with explicit overlay entry ownership.
- Build `MotionPathHero` on Flutter Hero's pairing and flight lifecycle.
- Add runtime-driven flight progress and plugin patch consumption.
- Support handoff from source Widget/RenderObject to overlay and back without duplicate global keys.
- Cover push, pop, reverse gesture, cancellation, route disposal, and missing destination cases.

## Phase 6: Headless and export

- Implement a headless renderer that records sampled frames and capability diagnostics.
- Add deterministic JSON snapshots for geometry, transforms, opacity, depth, and plugin fields.
- Use snapshots for cross-renderer parity and future recording/export tools.

## Phase 7: hardening

- Add golden tests for each renderer and mixed-renderer scenes.
- Add semantics and reduced-motion tests.
- Add image/filter/asset lifecycle tests.
- Benchmark 20, 250, and 1000 entities across Canvas, Widget, RenderObject, and mixed scenes.
- Profile frame fan-out, allocations, raster time, layer count, and repaint boundaries on real devices.

## Proposed package layout

```text
packages/motionpath_core/lib/src/rendering/
  frame.dart
  entity_id.dart
  renderer_capabilities.dart
  renderer_diagnostics.dart
  renderer_registry.dart

packages/motionpath_flutter/lib/src/renderers/
  motion_path_canvas_renderer.dart
  motion_path_widget_renderer.dart
  motion_path_render_object_renderer.dart
  motion_path_overlay_renderer.dart
  motion_path_headless_adapter.dart
  motion_path_renderer_binding.dart

packages/motionpath_flutter/lib/src/hero/
  motion_path_hero.dart
```

## Acceptance tests

- One engine tick publishes one frame consumed by Canvas and Widget renderers.
- A RenderObject list can update paint without rebuilding child widgets.
- A Hero flight can consume a full runtime motion, not only a path.
- Unsupported plugin fields fail clearly or follow a documented fallback.
- Renderer handoff preserves stable entity ID and current patch.
- Reduced motion produces an understandable destination state.
- All renderer resources detach cleanly after route replacement.
