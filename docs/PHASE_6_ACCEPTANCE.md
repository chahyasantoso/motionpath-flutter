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

## Remaining work

### P0: sampled runtime parity

- Add versioned fixtures for repeat, yoyo, delay, repeat delay, stagger, and completion events across multiple track durations.
- Add trajectory fixtures for path, FK, opacity, scale, color, z-depth, rotationX, and rotationY.
- Add lifecycle fixtures for mount, prepare, play, pause, seek, reverse, completion, unmount, and destroy.
- Add observation fixtures for input edges, output merges, diamonds, cycles, missing sources, and deterministic graph order.
- Add plugin fixtures for filter, CSS variables, overlay, spawner, image sequence, path, and FK outputs, including malformed diagnostics.

### P1: diagnostics parity

- Compare Dart and JS diagnostic codes, severity, JSON paths, and error categories for malformed projects.
- Cover duplicate ids, invalid triggers, invalid eases, bad stop ranges, invalid path controls, invalid anchors, bad image frames, path/x-y exclusivity, and non-finite numbers.
- Record every deliberate difference in `docs/COMPATIBILITY.md` with reason, owner, and regression test.

### P1: fixture tooling

- Keep JS-generated samples versioned and deterministic.
- Add a small fixture index mapping each JS case to its Dart test and tolerance rule.
- Make CI fail when a fixture is missing, malformed, or outside its documented tolerance.

## Closeout checklist

Phase 6 can move to **Complete** when:

- Every item above has either a passing fixture/test or an explicit documented exclusion.
- Core CI is green with the fixture suite enabled.
- Diagnostics agree for the covered malformed-input matrix.
- `docs/COMPATIBILITY.md` lists all intentional divergences.
- The Phase 6 row cites the final PRs and this document.

## Deliberate exclusions

Do not claim source parity for GSAP timelines, React hooks, DOM serializers, browser layout, Lenis, or Vite. Compare observable MotionPath behavior only.
