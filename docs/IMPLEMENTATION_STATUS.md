# Implementation status

Audited against merged pull requests and remote branches, not against memory.

## Completed

- Phases 0-8 (#1-#10): package boundaries, v4 contract and validation, observation graphs, pure runtime, trigger math, interpolation, painter boundary, FK, scroll bindings, and lifecycle-safe graph publication.
- Phase 9 (#11): easing families, colour interpolation, and Walker scene renderer.
- Phase 11 (#12): authored stagger timing.
- Phase 12 (#13): idempotent patch controller lifecycle.
- Phase 13 (#14): plugin contract validation.
- Phase 14 (#15): normalized polyline path plugin.
- Phase 15 (#16): discrete image sequence plugin.
- Phase 16 (#17): CSS custom property output.
- Phase 17 (#18): numeric filter group normalization.
- Phase 18 (#19): Overlay filtering and bounded Spawner expansion.
- Phase 19 (#20): local runtime benchmark harness.
- Phase 20 (#21): Flutter patch consumers.
- Phase 21 (#22): scroll driver and ticker lifecycle hardening.
- Phase 22 (#23): deterministic Walker scene geometry coverage.
- Phase 23 (#24): pluggable track composition layout policy.
- Phase 24 (#25): Flutter spawn and drain surface.
- Phase 25 (#26): explicit clock-neutral scroll scrub sampling.
- Phase 26: pure-Dart viewport samples and pinning policy, plus a Flutter binding that observes an existing ScrollPosition without creating a second frame source.

## Branch audit

Phases 10 and 22 were pushed straight to main without standalone PRs. `phase-23-status-and-branch-audit` never carried a commit. Every phase branch through phase 25 is merged and safe to delete.

## Next

- Drive the spawn surface from the ticker in a real scene.
- Add route-change lifecycle leak tests.
- Run controlled 14, 50, and 250-track benchmarks.
- Stabilize public APIs and write migration notes.

## Honest status

The viewport binding reports pin state and drives progress, but intentionally does not reposition widgets. Layout ownership remains with the host scene; clocks remain with the ticker or caller.
