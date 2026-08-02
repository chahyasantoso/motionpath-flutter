# Phase 6 acceptance gate

**Gate state: OPEN.**

Phase 6 proves behavioral parity against the JavaScript reference. It is not complete because a feature exists. It is complete when the Dart suite covers the contract boundary, sampled behavior, lifecycle events, and intentional divergences.

## Completed evidence on `main`

- PRs #91 through #110 cover authored payloads, path behavior, triggers, repeat boundaries, anchors, validation diagnostics, lifecycle controls, completion events, plugin edge contracts, whole-timeline trajectories, observation graphs, lifecycle matrices, repeat/stagger fixtures, and malformed-project diagnostics.
- PR #111 extracts the shared JSON fixture loader.
- PR #112 adds dedicated filter and CSS variable output fixtures.
- PR #113 adds the fixture index and metadata guard, including coverage for fixture-specific sample shapes.

## Remaining work

### Open divergence decision

- Eased overshoot is clamped away: `MotionPathInterpolators.number()` clamps `t` to `[0, 1]`, so `back.*` and `elastic.*` resolve correctly and then lose their overshoot at the value boundary. Confirm against the JS reference, then either fix the clamp or document it in `docs/COMPATIBILITY.md` with an owner and a regression test. Deliberately untested until the decision is made.

## Diagnostics parity: closed

PR #110 closes the diagnostics item. The matrix pins code, severity, JSON path, and message for twelve malformed projects, matched one-for-one with no surplus diagnostics allowed, and asserts severity against both `hasFatalErrors` and the `MotionPathProject.fromJson` trust boundary.

## Fixture tooling: closed

PRs #111 through #113 provide the shared loader, dedicated plugin fixtures, and the fixture index/metadata guard. Core CI now fails when a fixture is missing from the index, has an unknown case, lacks its harness, or declares malformed sample metadata.

## Closeout checklist

Phase 6 can move to **Complete** when the eased-overshoot candidate is either fixed with a parity regression test or explicitly documented as an intentional divergence with reason, owner, and test.

## Deliberate exclusions

Do not claim source parity for GSAP timelines, React hooks, DOM serializers, browser layout, Lenis, or Vite. Compare observable MotionPath behavior only.
