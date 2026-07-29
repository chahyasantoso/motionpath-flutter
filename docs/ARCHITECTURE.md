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
  -> renderer-neutral patch
  -> Flutter painter, render object, or widget adapter
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
  plugins/         plugin contracts and built-in data plugins
  math/            matrices, transforms, paths, forward kinematics
  contract/        public Dart types and JSON serialization
```

The core must not import `flutter`, access platform APIs, schedule frames, or produce CSS/widget objects.

## Flutter adapter

```text
packages/motionpath_flutter/lib/src/
  ticker/           Ticker-backed engine driver
  controllers/      MotionController and lifecycle ownership
  bindings/         scroll, gesture, and widget lifecycle adapters
  renderers/        patch consumers for widgets, canvas, and custom targets
  painters/         CustomPainter implementations and paint caches
  widgets/          optional declarative convenience widgets
```

The adapter converts Flutter time or scroll input into `Engine.tick(delta)` or `Motion.seek(progress)`. It should use `CustomPainter` or render objects for dense animation, not `setState` per property.

## Runtime lifecycle

`Engine.loadProject` validates and prepares a project without creating mounted runtime objects. `mountInstance` creates a Motion or Track. Ticks update progress, interpolate Track state, compose graph patches, and publish dirty nodes. `unmount` and `destroy` are idempotent and release every subscription and timeline-like resource.

## Graph model

Observation edges are normalized once into immutable JSON-safe nodes and edges. Diagnostics reject missing nodes, duplicate edges, self-cycles, cycles, invalid roles or targets, and ambiguous ownership. The compiled order is stable and parent-first. Diamonds reuse resolved context; cycles fail validation rather than relying on accidental runtime behavior.

## Rendering contract

A patch is plain Dart data. Plugins declare output metadata and internal keys. Renderers own serialization into `Matrix4`, `Paint`, layout values, or custom geometry. The core never knows whether a patch targets a widget, canvas, scene, or headless test.

## Scheduling rule

There is exactly one active frame source per engine integration. A Flutter adapter may use `Ticker`, but it must not create a second ticker, timer, or custom animation loop for the same engine. Scroll-driven motions are sampled through Flutter scroll notifications and mapped to `seek`.
