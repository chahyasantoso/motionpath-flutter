# MotionPath Flutter

Flutter and pure Dart implementation of MotionPath v4. The JavaScript repository remains the behavioral reference; this repository ports the contract, not the implementation.

## What this is for

MotionPath is a spatial interaction system for interfaces where motion needs to explain relationships, continuity, gesture outcomes, progress, or hierarchy. It is deliberately more structured than a one-off `AnimationController`: projects are validated, dependent tracks compose through a graph, user input can drive progress, and renderer-neutral patches can feed Flutter painters, render objects, widgets, or headless tests.

Use the built-in Flutter animation APIs for simple fades, scales, and route transitions. Reach for MotionPath when several elements share an authored path or timeline, when scroll/gesture input drives the scene, or when the same behavior must be reused across renderers without rebuilding the widget tree every frame.

## Repository map

- `packages/motionpath_core`: pure Dart schema, validation, graph compilation, runtime, interpolation, plugins, and math.
- `packages/motionpath_flutter`: Flutter scheduler, controllers, renderers, widgets, painters, and bindings.
- `example`: runnable reference scenes and the demo launcher.
- `test`: cross-runtime contract and performance tests.
- `fixtures`: JSON fixtures shared with the JavaScript reference repository.
- `docs`: architecture, compatibility, roadmap, wishlist, and product rationale.

## Principles

1. One scheduler. Flutter `Ticker` owns frame progression; no competing RAF or timer loop.
2. No widget state in the high-frequency path. Publish renderer-neutral patches directly to painters or render objects.
3. Core is Flutter-free and DOM-free.
4. Validate before parsing or mounting.
5. Compile observation graphs once and compose in stable parent-first order.
6. Motion must communicate a relationship, state change, gesture outcome, or progress. Decorative motion is not a product requirement.

The example launcher exposes ten completed demos: Walker, Burst, Motorcycle, Pasar Malam, Pasar Malam Observer, Tower Defense, Hooks Demo, Spiral / Zuma, Helix, and Carousel.

The next product-facing proposal is `MotionPathListView.builder`, a lazy path-following list that preserves normal Flutter list behavior. See [`docs/WISHLIST.md`](docs/WISHLIST.md) and the [MotionPathListView PRD](https://app.clickup.com/90141481884/docs/2kydkpww-474).

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/USE_CASES_AND_PRODUCT_RATIONALE.md`](docs/USE_CASES_AND_PRODUCT_RATIONALE.md), [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md), and [`docs/ROADMAP.md`](docs/ROADMAP.md).
