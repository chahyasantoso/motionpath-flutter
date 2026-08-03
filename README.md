# MotionPath Flutter

Flutter and pure Dart implementation of MotionPath v4. The JavaScript repository remains the behavioral reference; this repository ports the contract, not the implementation.

## What this is for

MotionPath is a spatial interaction system for interfaces and games where motion needs to explain relationships, continuity, gesture outcomes, progress, or hierarchy. It is more structured than a one-off `AnimationController`: projects are validated, dependent tracks compose through a graph, input can drive progress, and one renderer-neutral frame can feed multiple presentation targets.

Use Flutter's built-in animation APIs for simple fades, scales, and route transitions. Reach for MotionPath when several entities share an authored timeline or dependency graph, when scroll/gesture/game-loop input drives the scene, or when Canvas, widgets, render objects, overlays, and headless tests need the same behavior.

## Renderer model

Renderers work together. One runtime publishes immutable frames; each visual entity chooses one primary renderer. A scene can combine CanvasRenderer for dense visuals, WidgetRenderer for semantics and interaction, RenderObjectRenderer for high-frequency layout-aware children, OverlayRenderer for Hero flights and promoted entities, and HeadlessRenderer for deterministic samples and replay.

See [`docs/RENDERER_PRD.md`](docs/RENDERER_PRD.md), [`docs/RENDERER_IMPLEMENTATION_PLAN.md`](docs/RENDERER_IMPLEMENTATION_PLAN.md), and [`docs/RENDERER_CAPABILITY_MATRIX.md`](docs/RENDERER_CAPABILITY_MATRIX.md).

## Repository map

- `packages/motionpath_core`: pure Dart schema, validation, graph compilation, runtime, interpolation, plugins, and math.
- `packages/motionpath_flutter`: Flutter scheduler, controllers, renderers, widgets, painters, and bindings.
- `example`: runnable reference scenes and the demo launcher.
- `test`: cross-runtime contract and performance tests.
- `fixtures`: JSON fixtures shared with the JavaScript reference repository.
- `docs`: architecture, compatibility, roadmap, wishlist, and product rationale.

## Principles

1. One scheduler per engine integration.
2. No widget state in the high-frequency path.
3. Core is Flutter-free and DOM-free.
4. Validate before parsing or mounting.
5. Compile observation graphs once and compose in stable parent-first order.
6. Motion must communicate a relationship, state change, gesture outcome, or progress.
7. Renderer capability mismatches are explicit, never silently guessed.

The example launcher exposes ten completed demos: Walker, Burst, Motorcycle, Pasar Malam, Pasar Malam Observer, Tower Defense, Hooks Demo, Spiral / Zuma, Helix, and Carousel.

The next product-facing proposals are `MotionPathListView.builder` and formal renderer composition. See [`docs/WISHLIST.md`](docs/WISHLIST.md), the [MotionPathListView PRD](https://app.clickup.com/90141481884/docs/2kydkpww-474), and [`docs/ROADMAP.md`](docs/ROADMAP.md).

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/USE_CASES_AND_PRODUCT_RATIONALE.md`](docs/USE_CASES_AND_PRODUCT_RATIONALE.md), and [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md).
