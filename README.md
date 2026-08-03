# MotionPath Flutter

Flutter and pure Dart implementation of MotionPath v4. The JavaScript repository remains the behavioral reference; this repository ports the contract, not the implementation.

## Repository map

- `packages/motionpath_core`: pure Dart schema, validation, graph compilation, runtime, interpolation, plugins, and math.
- `packages/motionpath_flutter`: Flutter scheduler, controllers, renderers, widgets, painters, and bindings.
- `example`: runnable reference scenes and the demo launcher.
- `test`: cross-runtime contract and performance tests.
- `fixtures`: JSON fixtures shared with the JavaScript reference repository.
- `docs`: architecture, compatibility, and roadmap.

## Principles

1. One scheduler. Flutter `Ticker` owns frame progression; no competing RAF or timer loop.
2. No widget state in the high-frequency path. Publish renderer-neutral patches directly to painters or render objects.
3. Core is Flutter-free and DOM-free.
4. Validate before parsing or mounting.
5. Compile observation graphs once and compose in stable parent-first order.

The example launcher exposes ten completed demos: Walker, Burst, Motorcycle, Pasar Malam, Pasar Malam Observer, Tower Defense, Hooks Demo, Spiral / Zuma, Helix, and Carousel.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md), and [`docs/ROADMAP.md`](docs/ROADMAP.md).
