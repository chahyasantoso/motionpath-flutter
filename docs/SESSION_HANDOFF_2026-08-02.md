# MotionPath Flutter session handoff

Updated 2026-08-02 after PR #110 merged green.

## Repo and workflow

- Repository: `chahyasantoso/motionpath-flutter`
- Work directly on `main` for docs-only changes. No PR and no tests required.
- Code changes: branch, open PR, wait for all four CI jobs, inspect logs when red, fix on the same branch, rerun, then merge green.
- Keep a running play-by-play in chat. The user explicitly wants each step narrated.

## Current phase state

- Phases 0 through 5: Complete.
- Phase 6 Cross-repository parity: Partial and active, but now close to closeout.
- Phase 7 Carousel: Active, initial implementation and mount/scrub coverage merged. Untouched this session.
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
- #106: added whole-timeline trajectory fixtures with exact key-set assertions, covering path position, depth, opacity, scale, colour, 2D/3D rotation, three-bone FK world transforms, frame selection, and patch disappearance.
- #107: added observation graph parity fixtures for input edges, output merges, diamonds, cycles, missing sources, and deterministic order.
- #108: added the lifecycle parity fixture matrix across mount, prepare, play, pause, seek, reverse, completion, unmount, and destroy.
- #109: added repeat, yoyo, delay, repeat delay, stagger, and completion fixtures across multiple track durations.
- #110: added the malformed-project diagnostics matrix: twelve malformed projects with exact code, severity, JSON path, and message assertions, no surplus diagnostics allowed, plus fatality assertions against `hasFatalErrors` and the `MotionPathProject.fromJson` trust boundary.

## Next work, in order

### Phase 6 parity closeout

1. Add plugin output fixtures for `filter` and CSS variables. This is the last plugin gap: Overlay and Spawner landed in #104, image sequence, path, and FK outputs landed in #106, and malformed plugin diagnostics landed in #110.
2. Extract the duplicated fixture-loading helpers into one shared support file. Six `js_*_fixture_test.dart` files now repeat the same `jsonDecode`/`File.readAsStringSync` preamble.
3. Add the fixture index mapping each JS case to its Dart test and tolerance rule, and make CI fail when a fixture is missing, malformed, or outside tolerance.
4. Resolve the eased-overshoot divergence candidate: confirm against JS, then fix the clamp or document it in `docs/COMPATIBILITY.md` with an owner and a test.
5. Close Phase 6 only when every remaining item is green or explicitly documented as excluded.

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
- Value interpolation clamps `t` to `[0, 1]`, so overshooting eases never overshoot. Avoid `back.*` and `elastic.*` in value fixtures until that is resolved. Validation fixtures may still assert that `back.out(1.7)` is accepted as valid ease syntax, because that asserts no interpolated value.
- Any keyframe payload with fewer than two `stops` also trips `stop-count` plus the missing `p: 0` and `p: 1` warnings, including `path` and `imageSequence` payloads. Give payload fixtures real `p: 0`/`p: 1` stops unless the noise is the thing under test.
- Diagnostic paths are prefixed by their caller. Observation graph errors come out of `normalizeObservationGraph` as `tracks[i]...` and are re-emitted as `motions[m].tracks[i]...`.
- JSON cannot encode `Infinity` or `NaN`. The diagnostics fixture uses `@Infinity`, `@-Infinity`, and `@NaN` sentinels that the harness hydrates.
- Docs-only changes go straight to `main`; code changes need the full four-job gate.

## Session result

Phase 6 moved from sampled trajectory evidence to a near-complete parity suite. Observation, lifecycle, and trigger matrices landed in #107 through #109, and #110 closed the diagnostics item with an exact-match matrix that fails on surplus diagnostics as well as missing ones, plus a guard test that blocks any new diagnostic code from landing without a fixture. What is left in Phase 6 is small and well-bounded: two plugin fixture families, the shared fixture tooling, and one honest divergence decision. After that, the work returns to Phase 7 Carousel interaction and geometry coverage.
