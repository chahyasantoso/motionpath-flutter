# MotionPath Flutter

Flutter and pure Dart implementation of MotionPath v4. The JavaScript repository remains the behavioral reference; this repository ports the contract, not the implementation.

## What this is for

MotionPath is a spatial interaction and choreography system for interfaces and small game-like experiences where motion needs to explain relationships, continuity, gesture outcomes, progress, or hierarchy. Projects are validated, dependent tracks compose through a graph, input can drive progress, and immutable renderer-neutral frames can feed several Flutter renderers without rebuilding the widget tree every frame.

Use Flutter's built-in animation APIs for simple fades, scales, and route transitions. Reach for MotionPath when several elements share authored motion, scroll/gesture input drives the scene, the same entity moves between surfaces, or one runtime must coordinate Canvas, Widget, RenderObject, Overlay, and Headless outputs.

## Renderer model

One runtime frame can fan out to multiple renderers. Use one renderer per visual entity, not one renderer for the whole scene:

- **CanvasRenderer:** dense particles, bullets, maps, charts, and backgrounds.
- **WidgetRenderer:** interactive Flutter subtrees and semantic content.
- **RenderObjectRenderer:** high-volume transformed children, path lists, and layout-aware hit testing.
- **OverlayRenderer:** Hero flights, drag previews, portals, and route transitions.
- **HeadlessRenderer:** deterministic snapshots, recording, testing, and export.

The runtime owns truth. Renderers own target-specific presentation, resources, and hit testing.

## Repository map

- `packages/motionpath_core`: pure Dart schema, validation, graph compilation, runtime, interpolation, plugins, math, and renderer contracts.
- `packages/motionpath_flutter`: Flutter scheduler, controllers, renderers, widgets, painters, Hero integration, and bindings.
- `example`: runnable reference scenes and the demo launcher.
- `test`: cross-runtime contract and performance tests.
- `fixtures`: JSON fixtures shared with the JavaScript reference repository.
- `docs`: architecture, renderer plans, compatibility, roadmap, wishlist, and product rationale.

## Principles

1. One scheduler. Flutter `Ticker` owns frame progression; no competing RAF or timer loop.
2. No widget state in the high-frequency path. Publish immutable frames directly to painters or render objects.
3. Core is Flutter-free and DOM-free.
4. Validate before parsing or mounting.
5. Compile observation graphs once and compose in stable parent-first order.
6. Motion must communicate a relationship, state change, gesture outcome, or progress. Decorative motion is not a product requirement.
7. Semantics and reduced-motion behavior are cross-renderer requirements, not renderer afterthoughts.

The example launcher exposes ten completed demos: Walker, Burst, Motorcycle, Pasar Malam, Pasar Malam Observer, Tower Defense, Hooks Demo, Spiral / Zuma, Helix, and Carousel.

The next product-facing proposals are `MotionPathListView.builder` and `MotionPathHero.runtime`. See [`docs/WISHLIST.md`](docs/WISHLIST.md), the [MotionPathListView PRD](https://app.clickup.com/90141481884/docs/2kydkpww-474), and the renderer plans in [`docs/RENDERER_PRD.md`](docs/RENDERER_PRD.md).

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/USE_CASES_AND_PRODUCT_RATIONALE.md`](docs/USE_CASES_AND_PRODUCT_RATIONALE.md), [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md), and [`docs/ROADMAP.md`](docs/ROADMAP.md).
