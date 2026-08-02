# JavaScript to Dart compatibility contract

The `chahyasantoso/motionpath` v4.2 repository is the reference implementation.

## Preserve

- `schemaVersion: 4`
- project, motion, track, template, keyframe, stop, and observation field names
- `id`, `trigger`, `tracks`, and `observes`; never revive legacy `motionId`, `driver`, or playback wrappers
- `input` and `output` observation semantics
- deterministic graph ordering and actionable diagnostics
- compile-time plugin contribution and frame-time composition
- normalized renderer-neutral patches
- Engine ownership, mount, unmount, and destroy behavior
- `play`, `pause`, `seek`, `reverse`, repeat, yoyo, delay, repeat-delay, and scrub semantics

## Current parity status

The following reference behaviors are now covered in `main`:

| Contract area | Evidence | Status |
|---|---|---|
| Authored path and image payloads | PR #91 | Covered |
| Path autoRotate tangent output | PR #92 | Covered |
| Time autoplay defaults | PR #95 | Covered |
| Malformed path and image diagnostics | PR #96 | Covered |
| Repeat, yoyo, delay, repeatDelay, completion | PR #97 | Covered |
| Path stop easing before physical-distance sampling | PR #98 | Covered |
| Path anchors: center, none, explicit percentages | PR #99 | Covered |
| Path control warnings and normalized stop ranges | PR #100 | Covered |
| Path plus explicit x/y exclusivity | PR #101 | Covered |
| Sampled trajectories: position, depth, colour, 3D rotation, FK, frames, disappearance | PR #106 | Covered |
| Observation, lifecycle, repeat/stagger, plugin, and diagnostics fixtures | PRs #107 through #113 | Covered |
| Carousel interaction and geometry slices | PRs #114 through #119 | Covered |
| Carousel host interaction and scene-derived chrome | PRs #121 and #122 | Covered |
| Eased overshoot blend semantics | PR #123 | Covered |

## Eased overshoot parity

The JavaScript reference clamps the playhead to `[0, 1]` before interpolation, then lets the authored `back.*` and `elastic.*` curves produce the raw blend factor. Those curves intentionally overshoot numeric values.

Dart now matches this contract: `MotionPathInterpolators.linear()` clamps playhead progress, while `number()` preserves the raw eased factor. Authored endpoints and out-of-range playhead progress remain pinned by `interpolateStops`, and colour interpolation keeps its channel clamp. Regression coverage lives in `eased_overshoot_test.dart` from PR #123.

## Carousel scene mapping

The Flutter Carousel scene has executable parity evidence in PR #119: five authored path points with quadratic controls, `autoRotate: true`, opacity stops at 0, 0.15, 0.85, and 1, plus 0.1 stagger. PR #120 made the demo consume that definition and PR #122 made the stage guide painter derive from the same authored points, so the scene now exists exactly once in the Flutter tree.

## Accepted Carousel differences

These are deliberate Flutter-side choices, closed as part of the Phase 7 gate. None of them changes authored scene semantics, and none of them requires a schema decision.

| Difference | Reason | Owner | Regression evidence |
|---|---|---|---|
| Carousel does not use drain semantics; `drainOnComplete` stays Spiral-only | The Carousel scene removes cards through host interaction and reflow, not timeline drain | chahyasantoso | PRs #116 and #117 |
| Card identity is anchored with a scoped per-card `GlobalKey` | Keeps expensive card subtrees alive across patch-driven wrapper rebuilds in the current spawn architecture | chahyasantoso | PR #115 |
| Scroll progress is owned by a Flutter `ScrollPosition` | The reference stack's smooth-scroll and scroll-trigger libraries are implementation details, not contract | chahyasantoso | PRs #94 and #121 |
| Host interaction tests drive `ScrollPosition` directly instead of synthesizing drags | Gesture touch slop is a Flutter framework artifact with no reference analogue; letting it offset the scrub window would make authored progress assertions untestable | chahyasantoso | PR #121 |
| Authored end-boundary opacity is asserted at scene and geometry level, not in the host | The demo stage leaves the viewport before a card reaches progress 1, so the host covers the start boundary and both fade ramps | chahyasantoso | PRs #118, #119, and #121 |

## Stable subtree identity tradeoff

PR #115 uses a per-card `GlobalKey` as a scoped identity anchor so patch-driven wrapper rebuilds preserve the expensive card subtree. This is the safest closeout fix for the current wrapper architecture, not the only possible design. A future stable host, `AnimatedWidget`, or render-object layer could avoid GlobalKey overhead; that refactor is intentionally separate from parity closeout.

## Do not promise source parity

GSAP timelines, React hooks, DOM serializers, JavaScript proxies, Lenis, Vite, and browser layout delegates are implementation details. Dart should provide equivalent behavior through its own interpolation, ticker, Flutter bindings, and renderers.

## Compatibility policy

A contract change requires an explicit schema version decision and updates to both repositories. Do not silently accept legacy fields or alter validation severity to make a fixture pass.
