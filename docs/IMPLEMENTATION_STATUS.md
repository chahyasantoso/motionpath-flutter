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
- Phase 9:
  - Named easing registry: `none`/`linear`, `power1`-`power4`, the `quad`/`cubic`/`quart`/`quint`/`strong` aliases, `sine`, `circ`, `expo`, `back`, `elastic`, and `bounce`, each with `.in`, `.out`, and `.inOut`. A bare family name resolves to `.out` like the reference, an unknown name degrades to linear.
  - Authored `ease` is now honoured per stop, with a keyframe-level `ease` as the fallback. It was parsed and discarded before.
  - Colour properties (`color`, `backgroundColor`, `borderColor`) parse `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`, `rgb()`, `rgba()`, and common keywords into packed ARGB, then interpolate channel by channel.
  - Renderer boundary fix: composed `rotation` is authored DEGREES, and the painter was feeding it to `cos`/`sin` as radians. Conversion now happens once, in `MotionPathPatchTransform.rotationRadians`.
  - Walker scene renderer: bone table, joint dots, tones, ground, shadow, and head, driven straight off composed patches. The painter subscribes to the patch source, so a scrubbing rig repaints with no widget rebuild and no per-frame `setState`.
  - CI checkout action bumped to clear the Node 20 runner deprecation warning.

## Two real bugs fixed in Phase 9

1. Every authored `ease` was silently dropped. That was safe only because the Walker scene authors `"none"` on every stop; any other demo scene would have animated linearly and looked wrong with no error anywhere.
2. The renderer treated composed `rotation` as radians while the core composes degrees. A 90 degree joint rotated by roughly 5157 degrees. No existing test caught it because nothing asserted rotated geometry.

## Next

Port the remaining property plugins: path sampling, image sequences, filter groups, and CSS-variable output. Then wire the trigger delegates (scroll pinning and viewport observation) and the Spawner/Overlay use cases.

## Honest status

The engine composes a real FK rig end to end and now paints it as an actual skeleton rather than one diagnostic square per track. Scene coverage is asserted through resolved segment geometry, not image goldens: a committed pixel baseline is not worth maintaining until the scene stops changing every phase. The `elastic` and `bounce` curves are ported formulas with matching endpoints and shape, not byte-identical GSAP output. Property coverage is still numbers and colours only: no path sampling, no image sequences, no filter groups. Trigger delegates remain math, not bindings: nothing observes a viewport or pins a scroll section yet.
