# Renderer implementation plan

## Phase 0: inventory and invariants

- Inventory existing `MotionPathPatchView`, `MotionPathSpawnView`, painters, consumers, image cache, transforms, filters, depth, and hit testing.
- Document current patch keys and lifecycle ownership.
- Freeze the invariant that core publishes plain immutable data and renderers never mutate runtime state.
- Add a renderer decision record for intentional capability gaps.

## Phase 1: shared frame source

Create a Flutter-neutral frame source abstraction over `GraphPublisher`/patch sources.

- Immutable frame version and timestamp/progress.
- Interest-scoped entity and key filtering.
- Multiple listeners with independent attach/detach.
- No per-renderer runtime or ticker.
- Tests for ordering, coalescing, stale frame rejection, and disposal.

## Phase 2: capabilities and diagnostics

- Add renderer capability metadata.
- Add plugin output metadata and required/optional key classification.
- Validate compatibility before mount where possible.
- Add debug diagnostics for ignored keys, unsupported plugins, duplicate consumers, and lifecycle misuse.
- Add a capability matrix to `docs/RENDERER_CAPABILITY_MATRIX.md`.

## Phase 3: formalize existing adapters

- Wrap current painters as `CanvasRenderer`.
- Wrap patch and spawn views as `WidgetRenderer`.
- Keep stable child wrappers and image cache behavior.
- Separate renderer lifecycle from engine lifecycle.
- Add shared fixture tests proving old demos do not change.

## Phase 4: RenderObjectRenderer

- Implement `RenderMotionPathChild` and the list integration.
- Update transforms, opacity, filters, and z/depth during paint/compositing rather than `setState`.
- Add layout-aware transformed hit testing.
- Use this target for `MotionPathListView` and dense interactive children.
- Benchmark 20, 100, and 1000 logical items with stable keys.

## Phase 5: OverlayRenderer and Hero

- Define an overlay target contract for bounds, child identity, route direction, and cancellation.
- Implement `MotionPathHero` using `Hero.flightShuttleBuilder` and a shared frame source.
- Support any plugin fields accepted by the in-flight target, not only `path`.
- Test push, pop, user gesture reversal, cancellation, nested navigators, GlobalKey constraints, and disposal.

## Phase 6: Headless and recording

- Add a headless frame collector for deterministic tests and exported timelines.
- Add sampled-frame JSON output with schema/version metadata.
- Use it for golden comparisons and cross-renderer parity.
- Keep recording out of the hot path unless explicitly enabled.

## Phase 7: production hardening

- Add performance overlays and frame-cost telemetry in debug/profile builds.
- Verify memory ownership for image sequences, filters, and spawned children.
- Add reduced-motion and accessibility tests.
- Add documentation and examples showing one runtime feeding Canvas, Widget, RenderObject, and Overlay targets.
- Publish stable APIs only after capability and lifecycle contracts stop moving.

## Test strategy

- Contract tests: frame immutability, ordering, key interest, capability validation.
- Renderer tests: identical input fixture produces equivalent transform/opacity/depth samples.
- Widget tests: semantics, hit testing, route transitions, recycling, and stable identity.
- Golden tests: canvas, widget, render-object, and overlay snapshots.
- Performance tests: repaint counts, allocations, frame time, and 1000-entity scenes.
- Failure tests: unsupported plugins, missing assets, stale frames, disposal during flight, and reduced motion.

## Risks and mitigations

- **Abstraction bloat:** keep the contract small and capability-based.
- **Different visual semantics:** define equivalence at patch/frame level, not pixel identity.
- **Overlay complexity:** reuse Flutter Hero lifecycle rather than implementing a second Navigator system.
- **Performance regressions:** measure repaint boundaries and allocations before optimizing API shape.
- **Plugin mismatch:** fail early with actionable diagnostics.

## Definition of done

A production example uses one runtime to drive canvas particles, widget actors, a render-object path list, and one Hero overlay flight. The example has deterministic headless samples, capability diagnostics, semantics/reduced-motion coverage, clean teardown, and documented performance numbers.
