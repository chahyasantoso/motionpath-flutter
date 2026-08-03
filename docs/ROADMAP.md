# MotionPath Flutter engine roadmap

## Phase 0: foundation

- Create Dart workspace and package boundaries.
- Set Dart and Flutter version policy.
- Add formatting, analysis, unit-test, integration-test, and CI checks.
- Import the first shared JSON fixtures.

Exit criteria: both packages analyze cleanly, core tests run without Flutter, and fixture loading is deterministic.

## Phase 1: contract and validation

- Implement v4 schema types and JSON parsing.
- Implement collect-all validation and structured diagnostics.
- Reject legacy fields and malformed stops, triggers, plugins, and observations.
- Match reference fixture diagnostics.

Exit criteria: invalid projects fail before runtime objects or platform work are created.

## Phase 2: graph compiler

- Port immutable observation graph IR.
- Implement stable topological ordering.
- Implement cycle, duplicate-edge, missing-node, role, target, and ownership diagnostics.
- Add diamond and FK fixtures.

Exit criteria: Walker graph compiles once and produces the same order as the reference.

## Phase 3: pure runtime

- Implement interpolation stops and easing.
- Implement Track, Motion, triggers, and Engine ownership.
- Implement play, pause, seek, reverse, repeat, yoyo, delay, and manual progress.
- Implement plugin registration, contribution, composition, and patch merging.
- Implement GraphPublisher batching.

Exit criteria: core runs in a Dart VM test with no Flutter imports and matches sampled reference outputs.

## Phase 4: Flutter scheduling and renderers

- Add a Ticker-backed driver.
- Add MotionController lifecycle integration.
- Add scroll and gesture bindings.
- Add CustomPainter and canvas patch renderer.
- Add an optional widget adapter for simple tracks.

Exit criteria: one time-driven and one scroll-driven scene render correctly without per-frame `setState`.

## Phase 5: Walker and production hardening

- Port the Walker forward-kinematics demo.
- Add matrix and transform golden tests.
- Add lifecycle leak tests for route changes and disposed controllers.
- Benchmark 14, 50, and 250-track rigs.
- Profile paint invalidations and allocation pressure on mobile hardware.

Exit criteria: Walker behavior is compatible, teardown is clean, and performance budgets are documented.

## Phase 6: package release

- Stabilize public APIs and semver.
- Publish core and Flutter packages separately.
- Add API docs, migration guide, examples, and changelog.
- Establish fixture compatibility checks against the JavaScript repository.

Exit criteria: consumers can use pure Dart headlessly or Flutter rendering independently.

## Phase 7: product primitives

- Build `MotionPathListView.builder` on top of `CustomScrollView` and sliver-native lazy construction.
- Extract or share the canonical path sampler with the existing `path` plugin.
- Preserve controller behavior, recycling, semantics, reverse scroll, pagination, and stable keys.
- Validate two non-demo use cases: gesture education and a data-backed journey/process timeline.
- Add reduced-motion guidance and examples where motion explains state rather than decorates it.

Exit criteria: a team can ship a meaningful path-based interaction without hand-written scroll math, per-item runtimes, or abandoning native list behavior. See [`docs/WISHLIST.md`](WISHLIST.md) and [`docs/USE_CASES_AND_PRODUCT_RATIONALE.md`](USE_CASES_AND_PRODUCT_RATIONALE.md).

## Recommended first milestone

Build Phases 0 through 2 before writing widgets. The engine contract and graph compiler are the hard parts; a pretty demo before those are stable is just expensive wallpaper.

The next product milestone is not another showcase scene. It is a reusable list primitive plus two evidence-driven examples that prove the system reduces implementation cost and improves user orientation.
