# MotionPath Flutter Parity Implementation Plan

**Status:** Active  
**Owner:** Santo  
**Reference:** `chahyasantoso/motionpath` v4.x  
**Target:** Behavioral equivalence with the JavaScript implementation, not pixel parity.

## 1. Executive decision

The Flutter port should not be advanced by adding more demos first. The next move is to harden lifecycle ownership and establish one immutable renderer contract, then build the shared Flutter rendering layer. Carousel and Helix come after those foundations are proven.

The core architecture remains platform-free Dart. Flutter owns scheduling, widget composition, canvas rendering, image resolution, pin positioning, and depth ordering. Do not recreate GSAP timelines, React hooks, DOM serializers, or browser layout behavior inside the core.

## 2. Definition of done

The port is ready for a serious `0.1` release when:

- Core and Flutter packages analyze cleanly with strict lints and tests.
- Representative JS fixtures produce numerically equivalent sampled patches and lifecycle events.
- Runtime ownership is explicit: duplicate mounts, reloads, disposal, and callback wiring fail loudly and deterministically.
- Renderer-neutral patches are immutable snapshots with documented key semantics.
- A generic Flutter consumer renders transform, opacity, color, filters, image frames, and spawned instances without per-demo patch logic.
- Scroll scrub, pin state, dynamic spawning, and teardown are covered by widget tests.
- Carousel and Helix examples consume composed patches directly and do not duplicate engine math.
- Benchmarks cover 14, 50, and 250 tracks, including rebuilds, allocations, and paint invalidations.
- Package metadata, API docs, changelog, compatibility policy, and publish checks are complete.

## 3. Non-goals

Do not promise source parity for GSAP, React, DOM/CSS, Lenis, Vite, browser layout delegates, or CSS custom properties. Preserve the v4 contract and observable behavior instead.

Do not build a god-class named `ScrollTrigger`, speculative plugin registries, or a general timeline system. Extract abstractions only after the rule of three is met.

## 4. Delivery phases

### Phase 0: Baseline and guardrails

**Goal:** Make the current state measurable before changing behavior.

Tasks:

- Record the current commit SHA, Dart/Flutter versions, analyzer output, and test output.
- Add a parity test matrix mapping JS tests and fixtures to Dart tests.
- Define numeric comparison rules: exact equality for discrete values, tolerance-based equality for floating-point output.
- Add CI checks for formatting, strict analysis, core tests, Flutter tests, example tests, and generated-file hygiene.
- Add a `docs/PARITY_MATRIX.md` index once the first comparisons are mapped.

Exit criteria:

- A clean baseline report exists.
- Every later phase has a measurable regression signal.

### Phase 1: Lifecycle ownership and explicit failures

**Priority:** P0  
**Goal:** Remove silent state corruption and ownership leaks.

Tasks:

- Replace public callback fields on `MotionPathTrackRuntime` with guarded setters that throw `StateError` on double wiring in all build modes.
- Make `MotionPathMotionRuntime.prepare()` idempotent or reject repeated preparation explicitly; never duplicate observation edges.
- Reject duplicate motion IDs in `MotionPathEngine.mountMotion()` or dispose the previous runtime before replacement. Prefer rejection.
- Make `loadProject()` reject replacement while motions are mounted, or explicitly destroy mounted state before loading. Prefer rejection.
- Copy the `tracks` list on runtime construction and expose an immutable view. `dispose()` must never clear caller-owned collections.
- Make invalid trigger types and invalid easing names fail validation instead of silently becoming `time` or `linear`.
- Make malformed input observations fail explicitly instead of being ignored.
- Validate finite numeric values at parsing and runtime boundaries.
- Add tests for duplicate mount, repeated prepare, project reload, callback rewiring, non-finite numbers, malformed observations, and disposal.

Exit criteria:

- No lifecycle operation silently overwrites ownership.
- Release builds enforce the same invariants as debug builds.
- All new failure behavior has focused tests and documented error messages.

### Phase 2: Immutable patch contract

**Priority:** P0  
**Goal:** Make composed output safe to consume across engine and Flutter layers.

Tasks:

- Define the patch model and key classification: public output, internal keys, renderer metadata, and plugin-owned payloads.
- Publish immutable top-level and nested maps, or deep-copy at every public boundary if Dart collection freezing is not practical.
- Document units and semantics for `x`, `y`, `z`, rotations, scale, opacity, color, filters, images, instances, and custom properties.
- Add a shared patch normalizer that removes internal keys and applies output serializers before renderer consumption.
- Add tests proving consumers cannot mutate engine state through returned patches.
- Add sampled JS/Dart parity fixtures for every currently supported plugin.

Exit criteria:

- Renderer consumers receive a stable, documented snapshot shape.
- JS and Dart patch outputs agree within the documented tolerance.

### Phase 3: Shared Flutter renderer

**Priority:** P0  
**Goal:** Replace the diagnostic square with a reusable production-quality patch consumer.

Tasks:

- Upgrade `MotionPathPatchView` into a generic widget that accepts a child and applies patch-driven transform, opacity, color/filter effects, and visibility.
- Use `AnimatedBuilder.child` or a direct `CustomPainter(repaint:)` path so expensive child subtrees are not rebuilt per tick.
- Add a shared transform resolver for translation, rotation, scale, z, perspective, and supported 3D values.
- Add explicit behavior for unsupported keys. Unknown keys should be ignored only when they are not claimed by a renderer contract.
- Add image-frame resolution outside core, with a documented cache and disposal strategy.
- Add a shared custom-property consumer for numeric values. Do not pretend CSS variables map directly to Flutter; expose typed values to the host widget.
- Add filter composition with bounded values and tests for invalid sigma values.
- Add dirty checking so unchanged patches do not trigger unnecessary paint work.

Exit criteria:

- One generic consumer handles all supported patch keys.
- No demo reads individual authored keys to reproduce engine behavior.
- Widget, painter, and performance tests pass.

### Phase 4: Dynamic children and spawn lifecycle

**Priority:** P0  
**Goal:** Make spawning, reflow, and draining reusable rather than Spiral-specific.

Tasks:

- Move reflow tweening into a pure Dart numeric tweener with an explicit authored `Easing` parameter.
- Do not reuse scroll scrub's exponential-decay formula for fixed-duration reflow animation.
- Define one spawn surface API for mounting, reflowing, draining, and restart-wave behavior.
- Add deterministic ordering and stable identity rules for spawned children.
- Make hit testing and paint-order selection top-most-first for stacked children.
- Add a generic spawned-instance widget/painter host.
- Delete or refactor duplicate frame-triggered rebuild paths in the Spiral example.

Exit criteria:

- Spawn and reflow behavior is tested without Spiral-specific code.
- A host can render dynamic children from patches alone.
- No redundant `setState` or competing ticker is required.

### Phase 5: Scroll capabilities

**Priority:** P1  
**Goal:** Add only the scroll features required by real scenes.

Tasks:

- Keep scrub sampling, pin state, and viewport observation as separate capabilities.
- Add a small scroll-agnostic toggle-action state machine for enter, leave, enter-back, and leave-back callbacks.
- Implement pin repositioning through host widgets: use `SliverPersistentHeader` for common top pinning and explicit stack math for arbitrary pinning.
- Defer snap until a concrete scene requires it; define interruption behavior before implementation.
- Add attach, detach, reattach, route teardown, and mid-scroll disposal tests.

Exit criteria:

- Scroll functionality has no god-class and no hidden ticker.
- Pinned scenes behave deterministically during attach, detach, and disposal.

### Phase 6: Cross-repository behavioral parity

**Priority:** P1  
**Goal:** Prove the port against the JS reference instead of relying on structural similarity.

Tasks:

- Export deterministic sampled outputs from the JS reference for easing, triggers, repeats, yoyo, delay, stagger, path, FK, plugins, observations, and lifecycle events.
- Import those samples into Dart tests as versioned fixtures.
- Add trajectory/golden coverage for position, opacity, scale, color, z-depth, image frame selection, and patch disappearance.
- Compare malformed input diagnostics and error categories.
- Track intentional non-parity in `docs/COMPATIBILITY.md`, never silently diverge.

Exit criteria:

- A parity test fails when the JS contract changes or Dart behavior drifts.
- Every deliberate divergence has a reason, owner, and test.

### Phase 7: Carousel

**Priority:** P1  
**Goal:** First production-style demo using the shared renderer.

Tasks:

- Port the JS Carousel schema and behavior.
- Render cards from generic patch consumers only.
- Handle ordering, opacity, transforms, and any image payload through shared adapters.
- Add interaction and lifecycle tests.

Exit criteria:

- Carousel demonstrates that the renderer layer is reusable.
- No Carousel-only engine or patch interpretation exists.

### Phase 8: Helix and depth rendering

**Priority:** P2  
**Goal:** Add 3D behavior without contaminating core abstractions.

Tasks:

- Decide whether Helix uses Flutter `Matrix4` perspective directly or a pure-core projection utility. Prefer `Matrix4` when behavior is equivalent and no shared projection contract is needed.
- Define depth sorting explicitly because Flutter `Stack` has no CSS-like automatic `z-index`.
- Add stable sort rules for equal depth and avoid per-frame churn where possible.
- Add trajectory and widget golden tests across depth changes.

Exit criteria:

- Helix is behaviorally equivalent at sampled points.
- Depth ordering is deterministic and benchmarked.

### Phase 9: Release hardening

**Priority:** P1  
**Goal:** Make the packages publishable and maintainable.

Tasks:

- Generate API docs and review every public export.
- Classify APIs as stable, experimental, or internal.
- Replace the Flutter path dependency with a published core version.
- Remove `publish_to: none` only after dry-run checks pass.
- Add security review for untrusted JSON, resource loading, image memory limits, and unbounded instance expansion.
- Add benchmark reports with commit SHA, platform, SDK, and build mode.
- Update README, migration guide, compatibility policy, and changelog.

Exit criteria:

- `dart pub publish --dry-run` and `flutter pub publish --dry-run` pass.
- Release checklist is complete and CI is green.

## 5. Progress reporting

Update this section after every meaningful implementation batch. Keep reports factual and tied to exit criteria.

### Progress report template

```md
### YYYY-MM-DD: Phase N, short title

- Changed: files, APIs, or behavior changed.
- Verified: tests, analysis, fixtures, and benchmarks run.
- Result: pass, partial, or blocked.
- Risks: known regressions or follow-up work.
- Next: smallest next implementation slice.
```

### Current report

### 2026-07-31: Phase 5, toggle-action state machine

- Changed: added `MotionPathToggleStateMachine`, `MotionPathTriggerZone`, and `MotionPathToggleAction` to core; `MotionPathViewportBinding` now exposes `onToggle` and `zone`, resets crossing state on detach, and rejects an inverted authored window at construction.
- Verified: core and Flutter analysis plus the new `toggle_actions_test.dart` and `viewport_toggle_test.dart` suites, alongside the existing viewport and lifecycle tests.
- Result: partial. Scrub sampling, pin state, and crossings are now three separate capabilities with no god-class, but pin repositioning still has no host widget.
- Risks: crossings fire before `onSample`, which is a contract choice a host can depend on; changing it later is breaking. Snap remains deferred by design.
- Next: pin host widgets, `SliverPersistentHeader` for top pinning and explicit stack math for arbitrary pinning, with reattach and mid-scroll disposal tests.

### 2026-07-31: Phase 4, easing-aware spawn reflow

- Changed: `MotionPathSpawnController` now owns one `MotionPathValueTweener` per live child, seeded at spawn and at construction for adopted children, and a reflow retargets it instead of rebuilding it from a settled offset.
- Verified: `reflow_tween_test.dart`, the spawn controller and spawn view suites, and full CI across core, adapter, and example.
- Result: pass. Survivors slide into a freed slot over the authored duration and an interrupted reflow continues from the current animated offset.
- Risks: the tweener map is keyed by track identity, so a child detached without a removal callback is only pruned on the next rebuild.
- Next: Phase 5 scroll capabilities.

### 2026-07-31: Baseline review completed

- Changed: created this implementation plan; no runtime code changed.
- Verified: reviewed the Flutter core, Flutter adapter, example, tests, CI, and corresponding JS core capabilities.
- Result: partial. The core contract is credible, but lifecycle hardening, immutable patches, the generic renderer, full scroll capabilities, and cross-repository sampled parity remain.
- Risks: current examples can hide missing renderer consumption by recomputing visual state locally.
- Next: implement Phase 1 lifecycle ownership and explicit-failure fixes before adding Carousel or Helix.

## 6. Changelog

### 2026-07-31

- Added a scroll-agnostic toggle-action state machine and wired it into the viewport binding.
- Fixed spawn reflow so survivors tween into freed slots instead of teleporting.
- Added the end-to-end Flutter parity implementation plan.
- Recorded the recommended phase order, exit criteria, progress-report format, and release gates.
- Captured the current parity gaps and architectural guardrails.

## 7. Operating rules

- One active frame source per engine integration.
- Core remains pure Dart and owns contract, validation, composition, and lifecycle state.
- Flutter owns scheduling and rendering, not animation semantics.
- Every plugin output key gets one shared renderer consumer, never per-demo handling.
- Prefer explicit exceptions over silent fallback behavior.
- Keep abstractions small and evidence-driven. Rule of three before extraction.
- Behavioral equivalence beats pixel parity.
- Every implementation phase must add tests before or alongside code.
