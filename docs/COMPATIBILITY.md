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

## Do not promise source parity

GSAP timelines, React hooks, DOM serializers, JavaScript proxies, Lenis, Vite, and browser layout delegates are implementation details. Dart should provide equivalent behavior through its own interpolation, ticker, Flutter bindings, and renderers.

## Shared fixtures

Port fixtures from the reference repository into `fixtures/`: valid v4 projects, invalid schemas, Walker FK, diamond graphs, cycle graphs, manual motions, time motions, scroll motions, and patch serialization cases. Each fixture should have expected diagnostics or sampled output. Add a small script or test that proves Dart output matches the reference fixture expectations.

## Compatibility policy

A contract change requires an explicit schema version decision and updates to both repositories. Do not silently accept legacy fields or alter validation severity to make a fixture pass.
