# MotionPath Flutter session handoff

Updated 2026-08-02 after PR #120 merged green.

## Repo and workflow

- Repository: `chahyasantoso/motionpath-flutter`
- Work directly on `main` for docs-only changes. No PR and no tests required.
- Code changes: branch, open PR, wait for all four CI jobs, inspect logs when red, fix on the same branch, then merge green.
- Keep a running play-by-play in chat. The user explicitly wants each step narrated.

## Current phase state

- Phases 0 through 5: Complete.
- Phase 6 Cross-repository parity: Partial and near closeout. PRs #111 through #113 are merged; only the eased-overshoot divergence decision remains.
- Phase 7 Carousel: Active. PRs #114 through #120 are merged, covering reverse scroll, stable card subtrees, overlap hit testing, reflow, teardown, geometry samples, the shared scene contract, and the demo now consuming that shared scene.
- Phase 8 Helix/depth: Blocked until Phase 6 and Phase 7 mature.
- Phase 9 release hardening: Partial.

Authoritative closeout docs:

- `docs/PHASE_6_ACCEPTANCE.md`
- `docs/PHASE_7_ACCEPTANCE.md`
- `docs/PHASE_STATUS.md`
- `docs/COMPATIBILITY.md`

## Merged implementation slices

- #91: authored `path` and `imageSequence` payloads cross the JSON boundary and resolve through the default plugin registry.
- #92: path `autoRotate` emits tangent-aligned rotation.
- #93: scroll-driven Carousel example with dynamic children, shared patches, stagger, add/remove interaction, and front-most hit testing.
- #94: Carousel mount and real ListView scrubbing coverage; transformed card text overflow fix.
- #95: time autoplay defaults and distinct pause/manual/scroll semantics.
- #96: malformed path/image validation and analyzer cleanup.
- #97: repeat count, yoyo, delay, repeat-delay boundaries and completion math.
- #98: path stop easing before physical-distance sampling.
- #99: path anchors: `center`, `none`, explicit percentages.
- #100: JS path validation edge cases.
- #101: path plus explicit x/y rejected at validation.
- #102: one-shot completion events with restart/seek-back re-arming.
- #103: reverse, play/pause, seek-back, completion, unmount, destroy lifecycle coverage.
- #104: Overlay and Spawner plugin edge contracts.
- #105: ImageSequence stop type and frame-index validation.
- #106: whole-timeline trajectory fixtures with exact key-set assertions.
- #107: observation graph parity fixtures.
- #108: lifecycle parity fixture matrix.
- #109: repeat/yoyo/delay/repeat-delay/stagger/completion fixtures.
- #110: malformed-project diagnostics matrix.
- #111: shared JSON fixture loader.
- #112: dedicated filter and CSS variable parity fixtures.
- #113: fixture index and metadata guard.
- #114: reverse-scroll coverage preserving card identity, offsets, and playheads.
- #115: stable card subtrees across patch updates, with a scoped per-card `GlobalKey` identity anchor. A stable host/render-object design is a future alternative, not current scope.
- #116: overlapping-card front-most hit testing and middle-card removal/reflow without teleporting survivors.
- #117: Carousel teardown coverage for scroll/ticker binding disposal and controller hook cleanup. No drain semantics added; drain remains Spiral-only.
- #118: representative geometry assertions at 0, 0.15, 0.5, 0.85, and 1 for composed position, tangent rotation, center anchor, opacity, scale, and deterministic patches.
- #119: executable shared Carousel scene contract for five path points, quadratic controls, `autoRotate`, opacity boundaries, and 0.1 stagger.
- #120: `example/lib/carousel_scene.dart` extracted as the single authored scene definition; `carousel_demo.dart` consumes `carouselCardTrack` and `carouselCardStagger`, and the duplicated path/opacity literal is gone.

## Next work, in order

### Phase 6 closeout

1. Resolve eased-overshoot divergence: confirm the JS behavior, then either remove the numeric clamp and add parity fixtures or document the intentional divergence with owner, reason, and regression test.
2. Mark Phase 6 complete only after that decision is tested and recorded.

### Phase 7 Carousel closeout

1. Add actual widget interaction coverage for forward scroll, reverse scroll, add, remove, and re-entry against the shared scene, in the real demo host.
2. Assert card visibility in the widget host tracks the authored opacity stops, including cards hidden at the authored start boundary.
3. Record any intentional Flutter/JS differences, then close Phase 7 docs.

### After Phases 6 and 7

- Re-evaluate the Phase 8 Helix/depth gate.
- Then tackle Phase 9 release hardening: publishability, API docs, security, and release checklist evidence.

## Known sharp edges

- Path payload metadata (`stops`, `autoRotate`, `anchor`) must survive `propertiesFromTrack`.
- `path_plugin.dart` needs both interpolation imports.
- Preserve existing test coverage when adding validation cases.
- Analyzer is strict: run analyze before waiting on CI.
- `repeat` is repeat count, so total cycles are `repeat + 1`; repeat delays occur only between cycles.
- Value interpolation clamps `t` to `[0, 1]`; avoid overshooting value fixtures until the divergence decision is made.
- Carousel does not use drain semantics. `drainOnComplete` belongs to Spiral-style scenes.
- The scoped GlobalKey identity anchor is deliberate for current spawn wrappers; a stable host/render-object refactor could remove that overhead later.
- Docs-only changes go straight to `main`; code changes need the full four-job gate.
- The demo scene now lives in `example/lib/carousel_scene.dart`. Any authored change belongs there, not in `carousel_demo.dart`.
- The demo's scroll range and the stage position mean a card only reaches the authored end boundary after the stage has scrolled out of the viewport, so end-boundary evidence stays at the scene and geometry level.

## Session result

The parity suite is well instrumented, Carousel has coverage across interaction primitives, teardown, geometry, and scene mapping, and the demo consumes the shared scene definition. The next chat should start by adding real widget interaction coverage in the demo host, then record intentional differences and close Phase 7, while keeping the eased-overshoot decision visible as the only Phase 6 blocker.
