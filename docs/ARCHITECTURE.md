# MotionPath Flutter architecture

## Boundary

`motionpath_core` owns the portable animation engine. `motionpath_flutter` is an adapter layer. Examples never own engine behavior.

```text
JSON project
  -> validator
  -> resolved configs
  -> immutable observation graph IR
  -> Engine / Motion / Track
  -> GraphPublisher / FrameSource
  -> renderer-neutral immutable frame
  -> Canvas, Widget, RenderObject, Overlay, or Headless renderer
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
  composition/     plugin folds, patch merging, GraphPublisher, FrameSource
  plugins/         plugin contracts and built-in data plugins
  math/            matrices, transforms, paths, forward kinematics
  contract/        public Dart types and JSON serialization
```

The core must not import Flutter, access platform APIs, schedule frames, or produce CSS/widget objects.

## Renderer model

MotionPath uses a composable renderer model. One runtime publishes one immutable frame; multiple renderer instances may consume filtered views of that frame. Renderers are selected per visual entity, not per scene.

- **CanvasRenderer:** dense particles, bullets, maps, effects, and custom geometry.
- **WidgetRenderer:** interactive Flutter subtrees, semantics, focus, and inherited context.
- **RenderObjectRenderer:** high-frequency layout-aware children, transformed lists, and efficient hit testing.
- **OverlayRenderer:** Hero flights, route transitions, drag previews, and promoted entities.
- **HeadlessRenderer:** deterministic samples, tests, recording, and future adapters.

Every renderer declares capabilities. Plugins declare output metadata. Unsupported required outputs produce diagnostics; optional outputs may be intentionally ignored only when declared.

## Flutter adapter

```text
packages/motionpath_flutter/lib/src/
  ticker/           Ticker-backed engine driver
  controllers/      MotionController and lifecycle ownership
  bindings/         scroll, gesture, and widget lifecycle adapters
  renderers/        frame source, capabilities, canvas/widget/render/overlay adapters
  painters/         CustomPainter implementations and paint caches
  scene/            patch views, spawn views, and scene hosts
  list/             MotionPathListView and render-object list integration
```

The adapter converts Flutter time or scroll input into `Engine.tick(delta)` or `Motion.seek(progress)`. It should use `CustomPainter` or render objects for dense animation, not `setState` per property.

## Runtime lifecycle

`Engine.loadProject` validates and prepares a project without creating mounted runtime objects. `mountInstance` creates a Motion or Track. Ticks update progress, interpolate Track state, compose graph patches, and publish dirty nodes. `unmount` and `destroy` are idempotent and release every subscription and timeline-like resource.

A renderer may attach to a shared frame source and detach without destroying the runtime. Overlay and Hero adapters must also release route listeners and in-flight children on cancellation.

## Graph model

Observation edges are normalized once into immutable JSON-safe nodes and edges. Diagnostics reject missing nodes, duplicate edges, self-cycles, cycles, invalid roles or targets, and ambiguous ownership. The compiled order is stable and parent-first. Diamonds reuse resolved context; cycles fail validation rather than relying on accidental runtime behavior.

## Rendering contract

A patch is plain Dart data. Plugins declare output metadata, internal keys, and optional renderer requirements. Renderers own serialization into `Matrix4`, `Paint`, layout values, semantics, or custom geometry. The core never knows whether a patch targets a widget, canvas, scene, overlay, game entity, or headless test.

One entity has one primary renderer at a time. A scene may combine renderer types, and several renderers may subscribe to the same runtime without creating duplicate schedules.

## Scheduling rule

There is exactly one active frame source per engine integration. A Flutter adapter may use `Ticker`, but it must not create a second ticker, timer, or custom animation loop for the same engine. Scroll-driven motions are sampled through Flutter scroll notifications and mapped to `seek`.

## Open system work

The renderer contract is only one part of production readiness. The remaining system work includes stable scene/entity identity, asset preloading and eviction, capability diagnostics, transformed hit testing, semantics and reduced-motion policies, deterministic recording, frame budgeting, game-loop integration, authoring/tooling, schema migration, plugin versioning, structured runtime errors, and recovery policy. These are tracked in [`RENDERER_IMPLEMENTATION_PLAN.md`](RENDERER_IMPLEMENTATION_PLAN.md) and [`ROADMAP.md`](ROADMAP.md).
