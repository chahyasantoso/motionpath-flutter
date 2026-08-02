# MotionPath Flutter session handoff

Updated 2026-08-02 after PR #105 merged green.

## Repo and workflow

- Repository: `chahyasantoso/motionpath-flutter`
- Work directly on `main` for docs-only changes. No PR and no tests required.
- Code changes: branch, open PR, wait for all four CI jobs, inspect logs when red, fix on the same branch, rerun, then merge green.
- Keep a running play-by-play in chat. The user explicitly wants each step narrated.

## Current phase state

- Phases 0 through 5: Complete.
- Phase 6 Cross-repository parity: Partial and active.
- Phase 7 Carousel: Active, initial implementation and mount/scrub coverage merged.
- Phase 8 Helix/depth: Blocked until Phase 6 and Phase 7 mature.
- Phase 9 release hardening: Partial.

Authoritative closeout docs:

- `docs/PHASE_6_ACCEPTANCE.md`
- `docs/PHASE_7_ACCEPTANCE.md`
- `docs/PHASE_STATUS.md`
- `docs/COMPATIBILITY.md`

## Merged implementation slices

- #91: fixed default plugin registration and authored `path`/`imageSequence` payloads crossing the JSON boundary.
- #92: added path `autoRotate` tangent rotation.
- #93: added the scroll-driven Carousel example with shared patches, dynamic children, stagger, add/remove, and front-most hit testing.
- #94: added Carousel mount and real ListView scrubbing coverage; fixed transformed card text overflow.
- #95: parsed time triggers now autoplay by default; explicit pause, manual, and scroll remain distinct.
- #96: added validation for malformed path and image payloads; fixed analyzer imports/lints before merge.
- #97: fixed repeat completion math so `repeat` means repeat count, including yoyo and repeat-delay boundaries.
- #98: path stop easing now applies before physical-distance sampling; fixed missing interpolation imports and preserved path stops for plain paths.
- #99: added path anchors: `center`, `none`, and explicit `{xPercent, yPercent}`; fixed payload carry-through and restored precise diagnostics.
- #100: matched JS path validation for paired controls, first-point warnings, and normalized path stop ranges.
- #101: rejected path combined with explicit `x` or `y` at validation time.
- #102: added one-shot `MotionPathMotionRuntime.onComplete`, with restart and seek-back re-arming.
- #103: locked reverse, play/pause, seek-back, completion, unmount, and destroy lifecycle coverage.
- #104: added Overlay and Spawner plugin edge coverage.
- #105: added ImageSequence stop type and frame-index validation.

## Next work, in order

### Phase 6 parity closeout

1. Add deterministic trajectory fixtures for path, FK, opacity, scale, color, z-depth, rotationX, and rotationY.
2. Add observation fixtures for input edges, output merges, diamonds, cycles, missing sources, and graph ordering.
3. Expand lifecycle fixtures to cover mount, prepare, play, pause, seek, reverse, completion, unmount, and destroy as one mapped matrix.
4. Build the malformed-project diagnostics matrix: codes, severity, JSON paths, and error categories against JS.
5. Add the fixture index/tooling and record intentional divergences in `docs/COMPATIBILITY.md`.
6. Close Phase 6 only when every remaining item is green or explicitly documented as excluded.

### Phase 7 Carousel closeout

1. Add reverse-scroll and re-entry widget coverage.
2. Add add-card identity/stable-key coverage.
3. Add overlapping-card front-most hit-test coverage.
4. Add mid-chain removal/reflow coverage and prove survivors do not teleport.
5. Add teardown coverage while cards are mounted and after scroll disposal.
6. Add empty-carousel recovery and add-after-drain coverage.
7. Add representative geometry assertions or a stable golden at progress 0, 0.15, 0.5, 0.85, and 1.
8. Prove the card subtree stays stable while patches update.
9. Close Phase 7 docs only after all acceptance items are green.

## Known sharp edges

- Path payloads keep points plus metadata such as stops, autoRotate, and anchor. If metadata is dropped in `propertiesFromTrack`, the plugin silently loses behavior.
- `path_plugin.dart` needs both `interpolation/interpolator.dart` and `interpolation/easing.dart` imports.
- Preserve existing test coverage when adding validation cases. Do not replace a whole test file with a reduced subset.
- Analyzer is strict and CI runs `dart analyze --format machine` plus all tests. Fix unused imports and curly-brace lint findings before waiting on CI.
- `repeat` is repeat count, so total cycles are `repeat + 1`; repeat delays occur only between cycles.
- Docs-only changes go straight to `main`; code changes need the full four-job gate.

## Session result

The repo now has a credible path from parity bugs to acceptance gates: payload composition, trigger semantics, path behavior, validation diagnostics, lifecycle completion, and plugin edges are covered. The next meaningful move is not another demo. Finish the Phase 6 fixture matrix, then use that proof to close the Carousel with interaction and geometry coverage.
