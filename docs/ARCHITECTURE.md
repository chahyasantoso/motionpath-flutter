# MotionPath Flutter architecture

## Boundary

`motionpath_core` owns the portable animation engine. `motionpath_flutter` is an adapter layer. Examples never own engine behavior.

```text
JSON project
  -> validator
  -> resolved configs
  -> immutable observation graph IR
  -> Engine / Motion / Track
  -> GraphPublisher
  -> immutable runtime frame
  -> renderer fan-out
     -> CanvasRenderer
     -> WidgetRenderer
     -> RenderObjectRenderer
     -> OverlayRenderer
     -> HeadlessRenderer
```

## Pure Dart core

Suggested modules:

```text
packages/motionpath_core/lib/src/
  schema/          project parsing and template resolution
  validation/      collect-all diagnostics and validation error
  graph/           normalize, validate, and topologically order observations
  runtime/         Engine, Motion, Track, triggers, ownership, event bus
  interpolation/   stops, easing, normalized progress, repeat, yoyo
  composition/     plugin folds, patch merging, GraphPublisher
  rendering/       immutable frames, entity IDs, capabilities, diagnostics
  plugins/         plugin contracts and built-in data plugins
  math/            matrices, transforms, paths, forward kinematics
  contract/        public Dart types and JSON serialization
```

The core remains Flutter-free, platform-free, and renderer-neutral. It may describe output capabilities and data contracts, but never creates widgets, canvases, layers, overlays, or platform handles.

## Flutter adapter

```text
packages/motionpath_flutter/lib/src/
  ticker/           Ticker-backed engine driver
  controllers/      MotionController and lifecycle ownership
  bindings/         scroll, gesture, and widget lifecycle adapters
  renderers/        Canvas, Widget, RenderObject, Overlay, and headless adapters
  painters/         CustomPainter implementations and paint caches
  hero/             MotionPathHero and Hero flight integration
  scene/            patch views, spawn views, scene composition
  scroll/           scroll bindings and path helpers
```

The adapter converts Flutter time or scroll input into `Engine.tick(delta)` or `Motion.seek(progress)`. One runtime frame may feed many renderer bindings, but each visual entity has one active presentation owner unless explicitly mirrored. Canvas and RenderObject adapters should use paint/layer invalidation rather than `setState` per property.

## Runtime lifecycle

`Engine.loadProject` validates and prepares a project without creating mounted runtime objects. `mountInstance` creates a Motion or Track. Ticks update progress, interpolate Track state, compose graph patches, publish one immutable frame, and fan it out to interested renderers. `unmount`, renderer detach, and `destroy` are idempotent and release every subscription, overlay entry, image handle, and timeline-like resource.

## Rendering contract

A frame contains stable entity IDs, immutable patch data, sample metadata, and dirty/interest information. Plugins declare output metadata and renderer capability requirements. Renderers own serialization into `Matrix4`, `Paint`, layout values, semantics, overlays, or custom geometry. Unsupported fields must follow an explicit consume, degrade, fallback, or reject policy.

Runtime graph order and visual paint order are separate. The runtime resolves dependencies parent-first; scene composition resolves z/depth and renderer layering afterward.

## Multi-renderer composition

Renderers work together. A game or app can draw dense particles on Canvas, interactive actors as Widgets, a path-following list through RenderObjects, and a selected item as an Overlay Hero, all from one runtime. Use one renderer per visual entity, not one renderer for the entire scene.

## Scheduling rule

There is exactly one active frame source per engine integration. A Flutter adapter may use `Ticker`, but it must not create a second ticker, timer, or custom animation loop for the same engine. Scroll-driven motions are sampled through Flutter scroll notifications and mapped to `seek`. Future game integrations should provide fixed-step input through the same engine boundary rather than adding a second truth source.

## Cross-cutting requirements

- Stable entity identity for renderer handoff and recycling.
- Semantics and focus order independent of visual paint order.
- Reduced-motion policy above individual renderers.
- Explicit asset/cache ownership and memory budgets.
- Deterministic snapshots for tests, replay, and future export.
- Diagnostics before mount for invalid capability combinations.
