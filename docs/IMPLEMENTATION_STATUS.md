# Implementation status

Audited against merged pull requests and remote branches, not against memory.

## Completed

- Phases 0-8 (#1-#10): package boundaries, the v4 contract and collect-all
  validation, the observation graph compiler, the pure Dart runtime, trigger
  math, per-property interpolation, the renderer-neutral painter boundary,
  forward kinematics, scroll bindings, and lifecycle-safe graph publication.
- Phase 9 (#11): authored easing families, per-channel colour interpolation,
  and the Walker scene renderer.
- Phase 11 (#12): authored motion stagger is applied to track playheads.
- Phase 12 (#13): patch controller disposal is idempotent and post-dispose
  operations are safe no-ops.
- Phase 13 (#14): plugin contracts validate names and declared fields, and
  duplicate registrations fail early.
- Phase 14 (#15): opt-in normalized polyline path plugin with malformed-path
  handling.
- Phase 15 (#16): opt-in discrete image sequence plugin; loading stays outside
  the pure Dart core.
- Phase 16 (#17): opt-in CSS custom property output with nested numeric map
  interpolation.
- Phase 17 (#18): opt-in numeric filter group normalization.
- Phase 18 (#19): opt-in Overlay field filtering and bounded Spawner instance
  expansion.
- Phase 19 (#20): a local runtime benchmark harness for 14, 50, and 250-track
  compositions.
- Phase 20 (#21): Flutter-side patch consumers for image frames, CSS custom
  properties, blur filters, and Spawner instances.
- Phase 21 (#22): idempotent scroll driver and ticker disposal, with no second
  frame source introduced.
- Phase 22 (#23): deterministic Walker scene geometry coverage instead of
  brittle pixel goldens.
- Phase 23: pluggable track composition layout policy. `LayoutDelegate`,
  `GaplessLayoutDelegate`, and `StaticLayoutDelegate` are ported from the
  reference, and runtime tracks now own the parent/child mechanics those
  policies exist to serve.

## Branch audit

Phases 10 and 22 have no pull request of their own: `phase-10-plugin-registry`,
`phase-8-plugins-fk-scroll`, `phase-9-easing-and-rig-renderer`, and
`phase-22-integration-hardening` were pushed straight to `main` and later
appeared only as the base commit of the next PR. `phase-23-status-and-branch-audit`
never carried a commit at all: it points at `main`, which is why this file still
listed the already-merged phases 19-22 work as upcoming. Every phase branch
through `phase-22-golden-scene-coverage` is merged and safe to delete.

## Next

- Give the host mechanics a real consumer: a Flutter-side spawn and drain
  surface that mounts composed children at their settled offsets.
- Add viewport observation and scroll pinning delegates without introducing a
  second frame source.
- Add lifecycle leak tests around widget route changes, not just around
  explicit disposal.
- Run the benchmark harness for 14, 50, and 250-track rigs in a controlled
  environment and record results per commit.
- Stabilize the public API surface and write the migration and compatibility
  notes needed before either package is published.

## Honest status

The pure Dart core parses, validates, composes, and publishes v4 projects, and
now models child placement policy the way the reference does. What it does not
do is schedule children: `currentOffset` is settled bookkeeping plus a host
hook, so a spawned child is placed but nothing advances its playhead until an
adapter mounts it. Image loading, CSS, and overlay rendering stay in adapters by
design. The benchmark harness reports local composition timing only and is not a
cross-machine performance claim. Scene coverage is resolved segment geometry
rather than committed pixel baselines, which is deliberate while the scene still
changes most phases.
