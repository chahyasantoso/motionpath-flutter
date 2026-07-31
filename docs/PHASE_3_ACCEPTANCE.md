# Phase 3 acceptance gate

Phase 3 is active after the green Phase 2 merge.

**Gate state: OPEN. Phase 3 is not complete.** Carousel and Helix remain
blocked.

## Required implementation

- Make `MotionPathPatchView` consume the shared patch contract for transform, opacity, color, visibility, filters, image frames, instances, CSS values, and supported 3D metadata.
- Keep child subtrees stable with `AnimatedBuilder.child` or a repaint-driven painter path.
- Define unsupported-key behavior and a shared transform resolver for translation, rotation, scale, z, perspective, and supported 3D values.
- Keep image loading, caching, and disposal outside core.
- Add dirty checking for unchanged patches.
- Add widget, painter, consumer, and performance tests.

## Compatibility constraints

- Do not change core animation semantics.
- Do not make demos reinterpret authored keys independently.
- Preserve the Walker whole-graph path.
- Do not begin Carousel or Helix until this gate is complete.

## Checklist

| Item | State | Evidence |
|---|---|---|
| Transform, opacity, blur consumption | Done | `MotionPathPatchView`, `MotionPathPatchTransform`, renderer tests. |
| Color and visibility consumption | Done | PR #73. Both wrappers are unconditional and identity-safe, and `Offstage` sits closest to the child so the effect chain stays observable. |
| Image frame, CSS variable, and instance payloads | Done | PR #73 host-owned builders plus `MotionPathPatchConsumers`. |
| Stable child subtree | Done | `AnimatedBuilder.child` with a fixed wrapper chain; no conditional wrapper remounts the child. |
| Dirty checking | Done | `motionPathPatchEquals` deep comparison drives per-track notification and `shouldRepaint`, replacing shallow `mapEquals`. |
| Interest-scoped per-track consumers | Done | `MotionPathPatchController.trackPatch()`, whole-graph fallback, notifier pruning. |
| One composition per update | Done | `MotionPathMotionRuntime.advance(delta, publishPatches: false)` separates advancement from composition; the controller no longer recomposes after `tick()`. |
| Zero-listener tick gating | Done | Frame-driven composition is gated; the playhead still advances and imperative `seek()`/`publish()` stay explicit. |
| Bounded filter composition and invalid-sigma tests | Done | Blur ignores non-finite and non-positive sigma, and clamps finite sigma to `kMotionPathMaxBlurSigma`. |
| z, perspective, and 3D in the shared transform resolver | **Open** | The resolver is 2D only. No z, perspective, or 3D key is read. |
| Explicit unsupported-key behavior | **Open** | Unknown keys are ignored, while claimed-but-unsupported renderer keys still need a surfaced policy. |
| Image resolution cache and disposal strategy | **Open** | The host receives a raw frame payload. No cache, no disposal contract. |
| Performance tests | **Open** | No renderer benchmark covering rebuilds, allocations, or paint invalidations. |
| Demo migration off local engine math | **Open** | The Spiral example still recomputes path position, color, visibility, and reflow locally. |

## Renderer key policy

Unknown patch keys are ignored at the Flutter boundary. Keys claimed by a
renderer contract must either be consumed or be listed as explicitly
unsupported in the contract and covered by tests. This prevents silent
per-demo reinterpretation while allowing plugin-owned payloads to pass to
host builders.

## Exit rule

Phase 3 is complete only when every item has implementation and tests, CI is green, the implementation plan and phase status are updated, and the PR is merged into `main`.
