# Migration guide

This repository ports the MotionPath v4 contract, not the JavaScript implementation details. The safest migration is to keep project JSON and scene intent, then replace the runtime and rendering boundaries deliberately.

## From JavaScript MotionPath

| JavaScript concept | Dart/Flutter replacement |
|---|---|
| `Engine` and `Motion` | `MotionPathEngine` and `MotionPathMotionRuntime` |
| GSAP ticker | `MotionPathTickerDriver` |
| `ScrollTriggerDelegate` | `MotionPathMotionScrollBinding` or `MotionPathViewportBinding` |
| `Track.compose()` patch | `MotionPathTrackRuntime.compose()` |
| `GraphPublisher` patch stream | `MotionPathPatchSource` or `MotionPathPatchController` |
| DOM renderer | `CustomPainter`, a render object, or a host widget consuming plain patches |
| `LayoutDelegate` | `MotionPathLayoutDelegate` with gapless or static policies |
| Spawner/Overlay use cases | Core renderer-neutral plugin contracts plus a Flutter host consumer |

## Porting rules

1. Keep `schemaVersion: 4` and the authored field names unchanged.
2. Parse and validate before mounting. Fatal diagnostics should block runtime creation.
3. Preserve observation roles: `input` feeds a named plugin input; `output` merges a source patch into the target patch.
4. Use one `MotionPathTickerDriver` per engine. Do not add a `Timer`, `AnimationController`, or another ticker to drive the same engine.
5. For scroll scenes, call `seek` from scroll samples. For scrub smoothing, pass caller-owned elapsed time; never hide a clock inside a binding.
6. Let the host own actual pinning and layout. `MotionPathViewportBinding` reports paint offset and pin state; it does not reposition widgets.
7. Dispose route-owned bindings in `State.dispose`. A disposed viewport binding is terminal and cannot be reattached.
8. Use `MotionPathSpawnController` for runtime child placement and draining. It advances from supplied elapsed time, and `MotionPathSpawnTickerBinding` connects it to the existing ticker without creating another frame source.

## Deliberate non-parity

Do not port GSAP timelines, JavaScript proxies, DOM serializers, React hooks, browser layout delegates, or CSS objects into the core. Preserve behavior at the patch and lifecycle boundaries instead.

## Before publishing an integration

- Run Dart and Flutter analysis and tests.
- Exercise route teardown and scroll detach/reattach.
- Verify every authored plugin key has an intentional renderer consumer.
- Record local benchmark metadata with the commit SHA, OS, CPU, Dart version, and complete JSON output.
