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

## Shared fixture

`fixtures/v4-project.json` is the Dart repository's canonical copy of the reference integration fixture. It intentionally covers a scroll-scrub motion, a time loop with stagger, an autoplay-disabled time motion, a manual motion, an image sequence, a reused template, a path track, a CSS custom property, and a standalone track.

The core compatibility test validates that the fixture has no fatal diagnostics and preserves its authored project, motion, template, and standalone-track shape. It does not claim that all renderer adapters are exercised by one parse test; plugin and renderer tests remain focused and deterministic.

## Do not promise source parity

GSAP timelines, React hooks, DOM serializers, JavaScript proxies, Lenis, Vite, and browser layout delegates are implementation details. Dart should provide equivalent behavior through its own interpolation, ticker, Flutter bindings, and renderers.

## Compatibility policy

A contract change requires an explicit schema version decision and updates to both repositories. Do not silently accept legacy fields or alter validation severity to make a fixture pass.
