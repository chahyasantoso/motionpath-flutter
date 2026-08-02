# Public API surface

This is the release-hardening classification for the exports in
`motionpath_core.dart` and `motionpath_flutter.dart`.

## Stable contract

These APIs define the v4 behavioral contract and are the compatibility surface:

- Project, motion, track, keyframe, stop, trigger, observation, and validation types.
- Runtime lifecycle: engine mount/load, motion prepare, track seek/play/pause/reverse,
  repeat/yoyo/delay, completion, and disposal.
- Renderer-neutral patch composition, immutable snapshots, graph publishing,
  plugin payload contracts, and easing/interpolation behavior.
- Flutter patch views, patch consumers, transform resolution, scroll/viewport
  bindings, pinned hosts, spawn lifecycle, deterministic depth ordering, and
  Matrix4 rendering.

Stable means behavior changes require an explicit compatibility decision and
regression evidence. Names and schema fields are preserved across the v4 line.

## Experimental adapters

These are public so applications can exercise the port, but their ergonomics
may change before the first published release:

- `MotionPathPatchController` and per-track notifier surfaces.
- `MotionPathSpawnController`, `MotionPathSpawnView`, reflow configuration,
  and host hit-testing callbacks.
- `MotionPathTickerDriver` and shared spawn ticker binding.
- `MotionPathWalkerScene`, rig painter, arbitrary pin host, and image cache.
- Example scene builders and demo-specific helpers are not package API.

Experimental changes must keep patch semantics and lifecycle ownership stable.

## Internal implementation

Files under `lib/src/` are implementation details even when re-exported by a
public entrypoint. Consumers should import only `package:motionpath_core/
motionpath_core.dart` or `package:motionpath_flutter/motionpath_flutter.dart`.

The following remain intentionally internal and are not exported:

- Private widget state, painter helpers, renderer wrapper classes, and test support.
- Platform-specific scheduling details and framework adapters not needed by hosts.
- Example-only scene definitions and visual chrome.

## Release rule

Before publishing, review every export against this classification. Promote an
experimental adapter only with focused tests, migration notes, and a changelog
entry. Do not promise source parity with GSAP, React, DOM/CSS, Lenis, Vite, or
browser layout; promise observable v4 behavior only.
