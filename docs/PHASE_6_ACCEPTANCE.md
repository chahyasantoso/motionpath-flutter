# Phase 6 acceptance gate

**Gate state: CLOSED.**

Phase 6 proves behavioral parity against the JavaScript reference. It is complete when the Dart suite covers the contract boundary, sampled behavior, lifecycle events, and intentional divergences.

## Completed evidence on `main`

- PRs #91 through #110 cover authored payloads, path behavior, triggers, repeat boundaries, anchors, validation diagnostics, lifecycle controls, completion events, plugin edge contracts, whole-timeline trajectories, observation graphs, lifecycle matrices, repeat/stagger fixtures, and malformed-project diagnostics.
- PR #111 extracts the shared JSON fixture loader.
- PR #112 adds dedicated filter and CSS variable output fixtures.
- PR #113 adds the fixture index and metadata guard, including coverage for fixture-specific sample shapes.
- PR #123 confirms the JavaScript eased-overshoot contract, removes the Dart value-level clamp, and adds regression coverage for `back.*`, `elastic.*`, endpoints, out-of-range playhead progress, composed tracks, colours, and non-overshooting curves.

## Eased overshoot decision: fixed, not accepted as a divergence

The JavaScript reference clamps the **playhead** before interpolation, then lets the authored easing curve produce the blend factor. `back.*` and `elastic.*` therefore overshoot authored numeric values by design.

Dart previously reused the playhead clamp as the numeric blend clamp, which flattened that overshoot. PR #123 changes `MotionPathInterpolators.number()` to blend with the raw eased factor. `interpolateStops` still pins authored endpoints and out-of-range progress, and colour interpolation keeps its channel clamp.

## Diagnostics parity: closed

PR #110 closes the diagnostics item. The matrix pins code, severity, JSON path, and message for twelve malformed projects, matched one-for-one with no surplus diagnostics allowed, and asserts severity against both `hasFatalErrors` and the `MotionPathProject.fromJson` trust boundary.

## Fixture tooling: closed

PRs #111 through #113 provide the shared loader, dedicated plugin fixtures, and the fixture index/metadata guard. Core CI fails when a fixture is missing from the index, has an unknown case, lacks its harness, or declares malformed sample metadata.

## Closeout checklist

- Eased overshoot matches the JavaScript reference. Done, PR #123.
- Regression coverage pins overshoot, endpoints, boundary clamping, colours, and unchanged curves. Done, PR #123.
- Intentional divergences remain explicit and are tracked separately in `docs/COMPATIBILITY.md`.

## Deliberate exclusions

Do not claim source parity for GSAP timelines, React hooks, DOM serializers, browser layout, Lenis, or Vite. Compare observable MotionPath behavior only.
