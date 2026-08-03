# Public API surface

This is the release-hardening classification for the exports in `motionpath_core.dart` and `motionpath_flutter.dart`.

## Stable contract

These APIs define the v4 behavioral contract and are the compatibility surface: project, motion, track, keyframe, stop, trigger, observation, validation, runtime lifecycle, renderer-neutral patch composition, immutable snapshots, graph publishing, plugin payload contracts, easing/interpolation, and the tested Flutter patch, scroll, viewport, pin, spawn, depth, and Matrix4 behaviors.

Stable means behavior changes require an explicit compatibility decision and regression evidence. Names and schema fields are preserved across the v4 line.

## Experimental adapters

These remain public so applications can exercise the port, but their ergonomics may change before the first published release:

- `MotionPathPatchController` and per-track notifier surfaces.
- `MotionPathSpawnController`, `MotionPathSpawnView`, reflow configuration, and host hit-testing callbacks.
- `MotionPathTickerDriver` and shared spawn ticker binding.
- `MotionPathWalkerScene`, rig painter, arbitrary pin host, and image cache.

Experimental changes must keep patch semantics and lifecycle ownership stable. The spawn view now has an explicit invariant wrapper and value-key identity contract; controller replacement and builder replacement remain release-hardening coverage items.

## Internal implementation

Files under `lib/src/` are implementation details even when re-exported by a public entrypoint. Consumers should import only the package entrypoints.

The following remain intentionally internal and are not exported: private widget state, painter helpers, renderer wrapper classes, test support, platform scheduling details, and example-only scene definitions.

## Export review rule

Before publishing, compare both entrypoints with this classification and record the result. Prefer an automated export inventory check so accidental public exposure fails CI. Promote an experimental adapter only with focused tests, migration notes, and a changelog entry.

Do not promise source parity with GSAP, React, DOM/CSS, Lenis, Vite, or browser layout; promise observable v4 behavior only.
