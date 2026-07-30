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
- Phase 23 (#24): pluggable track composition layout policy. `LayoutDelegate`,
  `GaplessLayoutDelegate`, and `StaticLayoutDelegate` are ported from the
  reference, and runtime tracks own the parent/child mechanics those policies
  exist to serve.
- Phase 24 (#25): a Flutter spawn and drain surface. Composed children are
  mounted at their settled offsets, their playheads are driven from the
  parent's elapsed time, and completed children drain back through the layout
  policy.
- Phase 25 (#26): scroll scrub sampling is explicit and clock-neutral. Flutter
  scroll bindings expose target/applied progress, apply core scrub math only
  when the caller supplies elapsed time, and reset state on detach.
- Phase 26 (#27): spawn surfaces subscribe to the existing engine ticker.
  Dynamic children advance from the same frame delta as mounted motions without
  a second ticker or competing clock.
- Phase 27 (#30, #32): viewport observation and pinning are clock-neutral. The
  Flutter adapter samples content-space geometry against a scroll position,
  reports visibility and pinned state, seeks the motion, and resets cleanly on
  detach. #32 is the final merged implementation; #28, #29, and #31 were
  superseded iterations and remain closed without merge.
- Phase 28 (#33): viewport binding disposal is terminal and idempotent. After
  route teardown, it cannot be reattached or sample a motion, and its state
  resets cleanly for lifecycle assertions.
- Phase 29 (#34): widget-level route teardown coverage proves the host disposes
  and detaches a viewport binding when its scene leaves the tree.
- Phase 30 (#35): controlled pure Dart benchmark reporting for 14, 50, and
  250-track compositions, with warmup, repeated runs, min/mean/max summaries,
  and JSON output suitable for local artifact capture.
- Phase 31 (#36): public API inventory, lifecycle rules, and JavaScript-to-Dart
  migration guidance are documented before package stabilization.
- Phase 32 (#37): package repository, issue tracker, documentation metadata, a
  changelog, and a publish checklist are in place. Packages remain unpublished
  and keep their local path dependency until the checklist is complete.
- Phase 33: a runnable Flutter example combines a clock-neutral pinned viewport
  item with dynamic children advanced by the shared ticker.

## Branch audit

Phases 10 and 22 have no pull request of their own: `phase-10-ci-and-contract`,
`phase-8-plugins-fk-scroll`, `phase-9-easing-and-rig-renderer`, and
`phase-22-integration-hardening` were pushed straight to `main` and later
appeared only as the base commit of the next PR. `phase-23-status-and-branch-audit`
never carried a commit at all. Every phase branch through
`phase-32-release-prep` is merged and safe to delete; the closed superseded
viewport iterations remain available for audit.

## Next

- Finish fixture compatibility review and decide the first publishable API
  subset.
- Replace the example's hand-built runtime with a shared v4 fixture once the
  fixture port lands.

## Honest status

The core and Flutter adapters now cover schema validation, graph composition,
renderer-neutral patches, scroll scrubbing, dynamic child placement and
  draining, shared-ticker advancement, and viewport geometry observation. The
viewport binding reports renderer-neutral pin state and paint offset but does
not mutate layout or scroll position; a host widget still owns actual pinned
rendering. Route teardown is covered at both binding and widget-host level, so
 disposed viewport bindings cannot leak listeners into a reused route. The
benchmark harness supports controlled local comparisons but remains explicitly
non-comparative across machines. Package metadata and release gates make the
unpublished status explicit. The example intentionally demonstrates the two
clock/lifecycle boundaries without claiming production scene coverage. Image
loading, CSS, and overlay rendering stay in adapters by design. Scene coverage
is resolved segment geometry rather than committed pixel baselines, which is
deliberate while the scene still changes most phases.
