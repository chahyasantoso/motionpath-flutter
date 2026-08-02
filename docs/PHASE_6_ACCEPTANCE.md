# Phase 6 acceptance gate

**Gate state: OPEN.**

Phase 6 proves behavioral parity against the JavaScript reference. It is not complete because a feature exists. It is complete when the Dart suite covers the contract boundary, sampled behavior, lifecycle events, and intentional divergences.

## Completed evidence on `main`

- PR #91: authored `path` and `imageSequence` payloads survive the JSON boundary and resolve through the default plugin registry.
- PR #92: path `autoRotate` emits tangent-aligned rotation.
- PR #95: parsed time triggers autoplay by default, while explicit pause, manual, and scroll semantics remain distinct.
- PR #96: malformed path and image payloads fail at validation with actionable diagnostics.
- PR #97: repeat count, yoyo, delay, repeat delay, and completion boundaries are covered.
- PR #98: authored path stop easing is applied before physical-distance sampling.
- PR #99: path anchors preserve `center`, `none`, and explicit percentage output.
- PR #100: first-point control warnings, paired controls, and normalized path stop ranges match the JS validator.
- PR #101: path plus explicit `x` or `y` is rejected as an output collision at validation time.
- PR #102: one-shot completion callbacks fire at the final advancing cycle and re-arm on restart or seek-back.
- PR #103: reverse, play/pause, seek-back, unmount, and destroy lifecycle behavior is covered.
- PR #104: Overlay and Spawner plugin edge contracts are covered.
- PR #105: ImageSequence stop types and frame-index ranges are validated.
- PR #106: whole-timeline trajectory fixtures sampled at nine progress points cover path position, `z` depth, `opacity`, `scale`, `color`, `rotation`, `rotationX`, `rotationY`, three-bone FK world transforms, image frame selection, and patch disappearance, each with an exact key-set assertion.
- PR #107: observation graph fixtures cover input edges, output merges, diamonds, cycles, missing sources, and deterministic graph order.
- PR #108: the lifecycle fixture matrix maps mount, prepare, play, pause, seek, reverse, completion, unmount, and destroy as one table.
- PR #109: versioned trigger fixtures cover delay, repeat, yoyo, repeat delay, completion, and stagger across multiple track durations.
- PR #110: the malformed-project diagnostics matrix pins code, severity, JSON path, and message for twelve malformed projects, matched one-for-one with no surplus diagnostics allowed, and asserts severity against both `hasFatalErrors` and the `MotionPathProject.fromJson` trust boundary.

## Remaining work

### P0: sampled runtime parity

- Add plugin output fixtures for `filter` and CSS variables. Overlay and Spawner contracts land in PR #104, image sequence, path, and FK outputs land in PR #106, and their malformed diagnostics land in PR #110, so these two are the last plugin gap.

### P1: fixture tooling

- Keep JS-generated samples versioned and deterministic.
- Add a small fixture index mapping each JS case to its Dart test and tolerance rule.
- Make CI fail when a fixture is missing, malformed, or outside its documented tolerance.
- Extract the duplicated fixture-loading helpers now living in `js_parity_fixture_test.dart`, `js_trajectory_parity_test.dart`, `js_observation_fixture_test.dart`, `js_lifecycle_fixture_test.dart`, `js_repeat_fixture_test.dart`, and `js_diagnostics_fixture_test.dart` into one shared support file.

### Open divergence candidate

- Eased overshoot is clamped away: `MotionPathInterpolators.number()` clamps `t` to `[0, 1]`, so `back.*` and `elastic.*` resolve correctly and then lose their overshoot at the value boundary. Confirm against the JS reference, then either fix the clamp or record it in `docs/COMPATIBILITY.md` with a reason and an owner. Deliberately untested for now, because pinning it would freeze a probable bug. See `docs/PARITY_MATRIX.md`.

## Diagnostics parity: closed

PR #110 closes the diagnostics item. The matrix covers duplicate ids, invalid triggers, invalid eases, bad stop ranges, invalid path controls, invalid anchors, bad image frames and indices, path/x-y exclusivity, non-finite numbers, observation edge errors, legacy v2/v3 fields, and non-numeric perspective. A guard test fails CI when a documented diagnostic code has no fixture, so new rules cannot land untested.

JSON cannot encode non-finite numbers, so the fixture uses `@Infinity`, `@-Infinity`, and `@NaN` sentinels hydrated by the harness. That is a fixture-encoding detail, not a behavioral divergence, and is documented in the fixture's own `notes`.

## Closeout checklist

Phase 6 can move to **Complete** when every item above has either a passing fixture/test or an explicit documented exclusion, core CI is green with the fixture suite enabled, diagnostics agree for the covered malformed-input matrix, and `docs/COMPATIBILITY.md` lists all intentional divergences.

## Deliberate exclusions

Do not claim source parity for GSAP timelines, React hooks, DOM serializers, browser layout, Lenis, or Vite. Compare observable MotionPath behavior only.
