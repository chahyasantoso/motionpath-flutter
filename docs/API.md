# Public API

MotionPath Flutter is split into two packages. Keep the dependency boundary honest: use the core package when you need deterministic animation state without Flutter, and use the Flutter package only when you need scheduling, scroll input, or rendering.

## `motionpath_core`

Import `package:motionpath_core/motionpath_core.dart`.

Stable entry points:

- **Contract and validation**: `MotionPathProject`, `MotionPathMotion`, `MotionPathTrack`, `MotionPathStop`, `MotionPathDiagnostic`, `MotionPathValidationException`, `validateProject`.
- **Runtime ownership**: `MotionPathEngine`, `MotionPathMotionRuntime`, `MotionPathTrackRuntime`, `MotionPathTrigger`.
- **Composition**: `ObservationGraph`, `GraphPublisher`, `composePatch`, `mergePatches`, `MotionPathPlugin`, `MotionPathPluginRegistry`.
- **Interpolation and math**: `interpolateStops`, easing resolvers, colour blending, forward-kinematics helpers, scroll progress and scrub math.
- **Built-in plugins**: path, image sequence, CSS variable, filter, Overlay, Spawner, and forward kinematics contracts.
- **Dynamic child layout**: `MotionPathLayoutDelegate`, `MotionPathGaplessLayoutDelegate`, `MotionPathStaticLayoutDelegate`, and the runtime track child APIs.

The core never imports Flutter, starts a frame source, loads images, mutates layout, or emits CSS/widget objects. Its output is plain Dart patch data.

## `motionpath_flutter`

Import `package:motionpath_flutter/motionpath_flutter.dart`.

Stable adapter boundaries:

- **Scheduling**: `MotionPathTickerDriver` owns the single Flutter ticker for an engine.
- **Patch publication**: `MotionPathPatchController`, `MotionPathPatchSource`.
- **Scroll and viewport input**: `MotionPathMotionScrollBinding`, `MotionPathScrollDriver`, `MotionPathViewportBinding`.
- **Dynamic children**: `MotionPathSpawnController`, `MotionPathSpawnTickerBinding`, `MotionPathSpawnInstance`.
- **Patch consumers and painters**: `MotionPathPatchConsumers`, `MotionPathPatchPainter`, `MotionPathRigPainter`, `MotionPathWalkerScene`, `MotionPathPatchView`.

Adapters translate input or patches. They do not replace engine behavior, create a second clock, or silently mutate host layout.

## Lifecycle rules

- Call `dispose()` on every ticker driver, scroll driver, viewport binding, controller, and spawn binding you create.
- Disposal is idempotent. Viewport binding disposal is terminal: do not reuse a disposed binding.
- Detach before reattaching reusable scroll/viewport bindings. Detach resets sampled state.
- Keep one ticker per engine integration. Scroll and viewport bindings sample or seek; they do not tick.
- Treat patch maps as immutable snapshots. Copy data before retaining and mutating it in a host.

## Compatibility

The JSON contract is v4. Do not revive legacy `motionId`, `driver`, `timelineId`, `primary`, `lifecycle`, or `playback` fields. See [`COMPATIBILITY.md`](COMPATIBILITY.md) for the behavior contract and [`MIGRATION.md`](MIGRATION.md) for porting guidance.
