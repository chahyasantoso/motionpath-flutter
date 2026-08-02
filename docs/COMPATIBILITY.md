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
- `play`, `pause`, `seek`, `reverse`, repeat, yoyo, delay, and scrub semantics

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

## Suspected divergence, not yet accepted

Eased overshoot is clamped away. `MotionPathInterpolators.number()` clamps `t` to `[0, 1]` before blending, so `back.*` and `elastic.*` resolve to the correct curve and then lose their overshoot at the value boundary. The JS reference is expected to overshoot. This remains an explicit open decision, not an accepted difference. Confirm against the JS reference, then either fix the clamp or document it with an owner and a regression test.

## Carousel scene mapping

The Flutter Carousel scene now has executable parity evidence in PR #119: five authored path points with quadratic controls, `autoRotate: true`, opacity stops at 0, 0.15, 0.85, and 1, plus 0.1 stagger. The demo still contains its own scene literal; wiring it to the shared builder is the next task. The Flutter implementation intentionally uses shared renderer patches and does not use Spiral's drain semantics.

## Stable subtree identity tradeoff

PR #115 uses a per-card `GlobalKey` as a scoped identity anchor so patch-driven wrapper rebuilds preserve the expensive card subtree. This is the safest closeout fix for the current wrapper architecture, not the only possible design. A future stable host, `AnimatedWidget`, or render-object layer could avoid GlobalKey overhead; that refactor is intentionally separate from parity closeout.

## Do not promise source parity

GSAP timelines, React hooks, DOM serializers, JavaScript proxies, Lenis, Vite, and browser layout delegates are implementation details. Dart should provide equivalent behavior through its own interpolation, ticker, Flutter bindings, and renderers.

## Compatibility policy

A contract change requires an explicit schema version decision and updates to both repositories. Do not silently accept legacy fields or alter validation severity to make a fixture pass.
