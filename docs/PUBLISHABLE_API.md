# First publishable API subset

This is the deliberately small surface to stabilize for the first public release. Everything else remains available in the packages but may change until it has a documented contract and fixture coverage.

## Core package

Publish these as stable:

- `MotionPathProject` and the v4 contract types.
- `validateProject` and `MotionPathValidationException`.
- `MotionPathEngine`, `MotionPathMotionRuntime`, and `MotionPathTrackRuntime` lifecycle methods.
- `MotionPathStop`, `interpolateStops`, and named easing resolution.
- `ObservationGraph`, graph normalization, and renderer-neutral patch composition.
- `MotionPathPlugin` and `MotionPathPluginRegistry` extension points.

Treat these as experimental for the first release:

- Dynamic child layout delegates and host callbacks.
- Built-in path, image-sequence, CSS-variable, filter, Overlay, and Spawner plugins.
- Benchmark helpers and fixture internals.

## Flutter package

Publish these as stable:

- `MotionPathTickerDriver` as the single engine clock.
- `MotionPathMotionScrollBinding` and `MotionPathViewportBinding` for clock-neutral input.
- `MotionPathPatchController` and `MotionPathPatchSource` for patch publication.
- `MotionPathPatchPainter` and the renderer-neutral patch consumer helpers.

Treat these as experimental for the first release:

- `MotionPathSpawnController` and `MotionPathSpawnTickerBinding`.
- `MotionPathWalkerScene` and `MotionPathRigPainter`.
- `MotionPathPatchView`, which is intentionally diagnostic.

## Stability rules

A stable API needs: public dartdoc, deterministic tests, lifecycle coverage where it owns resources, and a compatibility note when it maps to the JavaScript reference. Do not remove `publish_to: none` or publish either package until the stable subset has those gates and the release checklist is complete.
