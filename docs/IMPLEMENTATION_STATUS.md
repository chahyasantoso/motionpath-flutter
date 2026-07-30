# Implementation status

## Completed

- Phase 0: package boundaries, documentation, CI, analyzer configuration, and smoke tests.
- Phase 1: v4 project/motion/track contract, JSON parsing, structured diagnostics, and collect-all validation.
- Phase 2: immutable observation graph nodes and edges, stable topological ordering, diagnostics, and dependency policy.
- Phase 3: numeric interpolation, normalized Track progress, Motion playback controls, Engine lifecycle, mount-time graph compilation, and runtime tests.
- Phase 4: delay/repeat/yoyo trigger math, dirty-track GraphPublisher, and a single-source Flutter Ticker driver boundary.
- Phase 5: Engine tick propagation, authored keyframe stop extraction, and ticker-driven runtime progress.
- Phase 6: per-property interpolation patches and parent-first graph composition scaffolding.
- Phase 7: renderer-neutral Flutter patch painter supporting opacity, translation, rotation, scale, and basic colour handling.
- Phase 8: schema fidelity, plugin composition, forward kinematics, and Flutter scroll and rig bindings.

## Phase 8 detail

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
- A minimal plugin layer resolves authored keys into ordered plugins, strips internal keys from patches, and rejects output collisions at mount time.
- Forward-kinematics math accumulates world transforms in degrees, matching the reference runtime.
- Easing accepts GSAP style names such as `power2.inOut`, per stop or per property.

### Flutter adapter

- Scroll bindings map a scroll offset or an explicit window onto `Motion.seek` without creating a second frame source.
- `MotionPathPatchController` publishes composed patches through a `ChangeNotifier`, so painters repaint without per-property `setState`.
- `MotionPathRigPainter` draws an FK rig straight from composed patches.
- Patch rotation is interpreted as degrees at the renderer boundary and converted to radians once.

## Next

Port the Walker gait fixtures from the reference repository into a shared `fixtures/` directory with sampled expected output, add golden image tests for the rig renderer, add lifecycle leak tests for route changes, and benchmark 14, 50, and 250-track rigs.

## Honest status

The plugin layer is deliberately small: forward kinematics plus a passthrough for every other authored property. Path, image-sequence, CSS-variable, and 3D-projection plugins from the reference runtime are not ported, and neither are `Spawner` and `Overlay`. Stagger is parsed but not yet applied to track offsets, and colour values interpolate numerically rather than per channel.
