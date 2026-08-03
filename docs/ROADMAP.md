# MotionPath Flutter engine roadmap

## Phase 0: foundation

- Create Dart workspace and package boundaries.
- Set Dart and Flutter version policy.
- Add formatting, analysis, unit-test, integration-test, and CI checks.
- Import the first shared JSON fixtures.

## Phase 1: contract and validation

- Implement v4 schema types and JSON parsing.
- Implement collect-all validation and structured diagnostics.
- Reject legacy fields and malformed stops, triggers, plugins, and observations.

## Phase 2: graph compiler

- Port immutable observation graph IR.
- Implement stable topological ordering and graph diagnostics.
- Add diamond and FK fixtures.

## Phase 3: pure runtime

- Implement interpolation, easing, runtime ownership, plugin registration, composition, and GraphPublisher batching.

## Phase 4: Flutter scheduling and renderers

- Add Ticker, controller lifecycle, scroll and gesture bindings.
- Add CustomPainter and widget adapters.
- Add shared frame source and renderer capability metadata.

## Phase 5: production hardening

- Port Walker and add transform/lifecycle tests.
- Benchmark track rigs and paint invalidations.
- Add asset lifecycle, deterministic recording, error recovery, and reduced-motion policy.

## Phase 6: package release

- Stabilize public APIs and semver.
- Publish core and Flutter packages separately.
- Add API docs, migration guide, examples, changelog, and fixture compatibility checks.

## Phase 7: product primitives

- Build `MotionPathListView.builder` on sliver-native lazy construction.
- Preserve recycling, semantics, reverse scroll, pagination, and stable keys.
- Validate gesture education and a data-backed journey/process timeline.

## Phase 8: renderer formalization

- Ship the shared immutable frame source.
- Formalize CanvasRenderer, WidgetRenderer, RenderObjectRenderer, OverlayRenderer, and HeadlessRenderer.
- Add capability metadata, compatibility diagnostics, and the renderer matrix.
- Prove one runtime can feed multiple renderer types without duplicate tickers.
- Build `MotionPathHero` on Flutter Hero lifecycle and support plugin-driven in-flight choreography.

**Exit criteria:** a mixed scene uses Canvas, Widget, RenderObject, and Overlay outputs from one runtime, with deterministic headless samples and clean attach/detach behavior.

## Phase 9: system maturity

- Stable entity identity and scene ownership across route changes, recycling, spawn, and promotion to overlay.
- Asset prefetch/cache/eviction contracts.
- Transformed hit testing, semantic projections, and reduced-motion behavior.
- Frame budgeting, profiling, and backpressure for dense scenes.
- Game-loop adapter with fixed-step option, pause/resume, visibility, and deterministic replay.
- Authoring/tooling for inspecting graphs, previewing frames, and validating capability compatibility.
- Versioned schema migration, plugin versioning, structured runtime errors, and recovery policy.
- Cross-platform adapter experiments after Flutter contracts stabilize.

**Exit criteria:** production consumers can diagnose, profile, replay, and recover from renderer/runtime failures without patching engine internals.

## Recommended order

Do not add more showcase demos before proving the renderer contract. Build the shared frame source and capability diagnostics first, then RenderObject and Overlay targets, then the two product primitives. The missing foundation is not more animation features; it is ownership, observability, and predictable presentation boundaries.
