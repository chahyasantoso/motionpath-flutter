# Implementation status

Audited against merged pull requests and remote branches, not against memory.

## Completed

- Phases 0-8 (#1-#10): package boundaries, the v4 contract and collect-all validation, the observation graph compiler, the pure Dart runtime, trigger math, per-property interpolation, the renderer-neutral painter boundary, forward kinematics, scroll bindings, and lifecycle-safe graph publication.
- Phase 9 (#11): authored easing families, per-channel colour interpolation, and the Walker scene renderer.
- Phase 11 (#12): authored motion stagger is applied to track playheads.
- Phase 12 (#13): patch controller disposal is idempotent and post-dispose operations are safe no-ops.
- Phase 13 (#14): plugin contracts validate names and declared fields, and duplicate registrations fail early.
- Phase 14 (#15): opt-in normalized polyline path plugin with malformed-path handling.
- Phase 15 (#16): opt-in discrete image sequence plugin; loading stays outside the pure Dart core.
- Phase 16 (#17): opt-in CSS custom property output with nested numeric map interpolation.
- Phase 17 (#18): opt-in numeric filter group normalization.
- Phase 18 (#19): opt-in Overlay field filtering and bounded Spawner instance expansion.
- Phase 19 (#20): controlled pure Dart benchmark reporting for 14, 50, and 250-track compositions.
- Phase 20 (#21): Flutter-side patch consumers for image frames, CSS custom properties, blur filters, and Spawner instances.
- Phase 21 (#22): idempotent scroll driver and ticker disposal.
- Phase 22 (#23): deterministic Walker scene geometry coverage.
- Phase 23 (#24): pluggable track composition layout policy.
- Phase 24 (#25): Flutter spawn and drain surface.
- Phase 25 (#26): explicit, clock-neutral scroll scrub sampling.
- Phase 26 (#27): shared-ticker advancement for dynamic spawn surfaces.
- Phase 27 (#30, #32): clock-neutral viewport observation and pinning. #32 is the final merged implementation; #28, #29, and #31 were superseded.
- Phase 28 (#33): terminal viewport binding disposal.
- Phase 29 (#34): widget-level route teardown coverage.
- Phase 30 (#35): controlled benchmark warmup, repeated runs, summaries, and JSON output.
- Phase 31 (#36): public API inventory and JavaScript-to-Dart migration guide.
- Phase 32 (#37): package metadata, changelog, and release checklist.
- Phase 33 (#38): runnable pinned viewport plus dynamic spawn example.
- Phase 34 (#40): canonical v4 integration fixture and trust-boundary compatibility test. PR #39 was a duplicate branch and is closed as superseded.
- Phase 35 (#41): first publishable API subset is explicitly classified as stable or experimental, with package-level READMEs.
- Phase 36 (#42): fixed spawn visibility and added the Spiral/Zuma example.
- Phase 37: the example now uses the ticker listener disposer correctly, and CI analyzes and tests the example package instead of silently skipping it.
- Phase 38 (#49): JS-compatible path node controls, z coordinates, cubic elevation, and approximate arc-length sampling.
- Phase 39 (#50): JS-compatible cumulative-distance spiral geometry and physical-speed-based spawn spacing.
- Phase 40 (#51): JS-style entrance, exit, completion drain, and animated reflow visuals.

## Active

- Phase 41: JS wave lifecycle parity. Branch `phase-41-spiral-wave-reset` caps each wave at 30 balls and resets the spawn clock to the outer path endpoint after the final child drains, matching `Spawner.resetWave()` and `hostTrack.seek(0)`.

## Next

- Complete Phase 41, then add generated API docs and final trajectory/golden coverage.

## Honest status

The Flutter Spiral now matches the JS wave model: spawn a bounded wave, stop adding balls, let the wave drain, then restart at the beginning. The reset is explicit rather than relying on a stale elapsed clock, which was the cause of new balls appearing farther down the line and eventually draining immediately.
