# Implementation status

## Completed

- Phases 0-10: package boundaries, v4 contract and validation, observation graphs, pure runtime, trigger math, interpolation, forward kinematics, Flutter painter and bindings, schema fidelity, plugin composition, and lifecycle-safe graph publication.
- Phase 11: authored motion stagger is applied to track playheads, with focused timing coverage.
- Phase 12: patch controller disposal is idempotent and post-dispose operations are safe no-ops; standalone motions compose without a graph.
- Phase 13: plugin contracts validate names and declared fields, and duplicate registrations fail early.
- Phase 14: opt-in normalized polyline path plugin with malformed-path handling.
- Phase 15: opt-in discrete image sequence plugin; loading remains outside the pure Dart core.
- Phase 16: opt-in CSS custom property output with nested numeric map interpolation.
- Phase 17: opt-in numeric filter group normalization.
- Phase 18: opt-in Overlay field filtering and bounded Spawner instance expansion.

## Next

- Add renderer-side consumers for image, CSS variable, filter, Overlay, and Spawner patches.
- Add viewport observation and scroll pinning delegates without introducing a second frame source.
- Add golden scene coverage and lifecycle leak tests around widget route changes.
- Run the benchmark harness for 14, 50, and 250-track rigs in a controlled environment and record results per commit.

## Honest status

The pure Dart core now has explicit, opt-in contracts for the remaining property families, but it does not load images, touch CSS, or render overlays itself. Those responsibilities stay in adapters. The benchmark harness reports local composition timing only; its output is not a cross-machine performance claim. The next meaningful work is renderer integration and viewport lifecycle behavior, not more placeholder plugins.
