# Implementation status

## Completed

- Phase 0: package boundaries, documentation, CI, analyzer configuration, and smoke tests.
- Phase 1: v4 project/motion/track contract, JSON parsing, structured diagnostics, and collect-all validation.
- Phase 2: immutable observation graph nodes and edges, stable topological ordering, diagnostics, and dependency policy.
- Phase 3: numeric interpolation, normalized Track progress, Motion playback controls, Engine lifecycle, mount-time graph compilation, and runtime tests.
- Phase 4: delay/repeat/yoyo trigger math, dirty-track GraphPublisher, and a single-source Flutter Ticker driver boundary.
- Phase 5: Engine tick propagation, authored keyframe stop extraction, and ticker-driven runtime progress.
- Phase 6: per-property interpolation patches and parent-first graph composition scaffolding.
- Phase 7: renderer-neutral Flutter patch painter supporting opacity, translation, rotation, scale, and colour.
- Phase 8:
  - `composeWorld` ported from the JavaScript `fkMath` boundary, with degrees kept as the authored unit.
  - Forward kinematics folding: `parentWorld` plus `boneLength`/`boneRotation` become flat world `x`/`y`/`rotation`, and internal keys never reach a renderer.
  - Observation edges now carry the authored `target` key, so an input edge lands under `parentWorld` instead of the source id.
  - v4 JSON parsing for motion tracks, keyframes, `duration`, and `observes`, plus project-level track libraries.
  - `GraphPublisher` composes the full graph parent-first and publishes only dirty tracks, matching the reference runtime.
  - Renderer-neutral scroll progress and scrub smoothing in the core, with a Flutter `ScrollController` driver on top.
  - Composed patches reach painter invalidation through `MotionPathPatchSource`, a `ChangeNotifier` fed by `Motion.onPatches`.
  - Walker FK rig fixtures ported from the demo, asserting bone-length invariants, knee bend, head bob, and forward travel.

## Next

Port the Walker scene renderer (bones, joints, and tones) on top of the composed patches, add golden tests for it, then port the remaining property plugins: path sampling, image sequences, filters, and colour interpolation. After that, wire trigger delegates (scroll pinning, viewport observation) and the Spawner/Overlay use cases.

## Honest status

The engine now composes a real FK rig end to end and paints it, but the only renderer is still one diagnostic square per track. Property coverage is numeric interpolation only: no path sampling, no colour interpolation between authored colours, no per-segment easing (authored `ease` values are parsed and ignored, which is safe while the demo scenes author `"none"`). Trigger delegates are math, not bindings: nothing yet observes a viewport or pins a scroll section.
