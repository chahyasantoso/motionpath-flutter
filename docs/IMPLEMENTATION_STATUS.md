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
- Phase 10: schema fidelity, plugin composition, cycle-safe graph composition, and Flutter scroll and rig bindings.

## Phase 10 detail

### Contract and validation

- Motion `tracks` and track `keyframes`, `stops`, `observes`, `use`, and `duration` are parsed instead of silently dropped. Before this, every mounted motion had zero tracks.
- Track templates resolve at parse time, so the runtime never sees a `use` reference.
- Diagnostics carry the reference rule ids (`schema-version`, `motion-structure`, `trigger-shape`, `stop-count`, `stop-shape`, `stop-sequence`, `track-observations*`) plus a severity, so an authoring warning no longer blocks loading.
- Forbidden v2/v3 fields (`motionId`, `driver`, `timelineId`, `primary`, `lifecycle`, `playback`) each produce their own error.
- Trigger validation covers `time`, `manual`, and `scroll`, including scrub requirements and the repeat/yoyo/repeatDelay/delay/duration incompatibilities.

### Graph and composition

- `input` observations preserve their authored `target`, so a source patch is wrapped as `{ parentWorld: sourcePatch }` before the child's plugins compose. That key was previously dropped, which made forward kinematics impossible.
- `input` edges now require a non-empty target and `output` edges reject one, matching the reference IR.
- Composition uses a per-call context with a composing sentinel, so cycles degrade to a local compose and diamonds resolve once per flush.
- A minimal plugin layer resolves authored keys into ordered plugins, strips internal keys from patches, and rejects output collisions at mount time. Any key no plugin claims falls back to a passthrough, so authored data is never silently dropped.
- Forward-kinematics math accumulates world transforms in degrees, matching the reference runtime.
- Interpolation now runs through the Phase 9 easing registry and the per-channel colour blend, so authored `power2.inOut` and authored colours both survive a plugin-composed track.

### Flutter adapter

- Scroll bindings map a scroll offset or an explicit window onto `Motion.seek` without creating a second frame source. The adapter class is `MotionPathMotionScrollBinding`; the core keeps the renderer-neutral `MotionPathScrollBinding` that owns the offset-window and scrub math.
- `MotionPathPatchController` publishes composed patches through a `ChangeNotifier`, so painters repaint without per-property `setState`. It sits alongside `MotionPathPatchSource`, which binds to `Motion.onPatches` for tick-driven scenes.
- `MotionPathRigPainter` draws an FK rig straight from composed patches.

## Two real bugs fixed in Phase 9

1. Every authored `ease` was silently dropped. That was safe only because the Walker scene authors `"none"` on every stop; any other demo scene would have animated linearly and looked wrong with no error anywhere.
2. The renderer treated composed `rotation` as radians while the core composes degrees. A 90 degree joint rotated by roughly 5157 degrees. No existing test caught it because nothing asserted rotated geometry.

## Next

Port the remaining property plugins: path sampling, image sequences, filter groups, and CSS-variable output. Then wire the trigger delegates (scroll pinning and viewport observation) and the Spawner/Overlay use cases. Move the Walker gait fixtures into a shared `fixtures/` directory with sampled expected output, add lifecycle leak tests for route changes, and benchmark 14, 50, and 250-track rigs.

## Honest status

The engine composes a real FK rig end to end and now paints it as an actual skeleton rather than one diagnostic square per track. Scene coverage is asserted through resolved segment geometry, not image goldens: a committed pixel baseline is not worth maintaining until the scene stops changing every phase. The `elastic` and `bounce` curves are ported formulas with matching endpoints and shape, not byte-identical GSAP output. The plugin layer is deliberately small: forward kinematics plus a passthrough for every other authored property. Path, image-sequence, CSS-variable, and 3D-projection plugins are not ported, and neither are `Spawner` and `Overlay`. Stagger is parsed but not yet applied to track offsets. Trigger delegates remain math, not bindings: nothing observes a viewport or pins a scroll section yet.
