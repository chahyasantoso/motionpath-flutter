# Phase 5 acceptance gate

**Gate state: READY TO CLOSE.**

Phase 5 scroll capabilities are implemented and covered end to end across
PR #88 and this PR. Close the phase when this change is green and merged.

## Completed scope

- `MotionPathScrollBinding` maps scroll offsets to normalized progress with
  authored scrub smoothing, and knows nothing about Flutter.
- `MotionPathViewportBinding` samples viewport geometry, seeks the motion from
  the sampled progress, and reports authored window crossings through the
  shared toggle state machine. It never starts a clock.
- Common top pinning ships as `MotionPathPinnedHeader` over
  `SliverPersistentHeader`.
- Arbitrary pinning ships as `MotionPathArbitraryPinned`, positioned inside a
  host `Stack` from `MotionPathViewportSample.paintOffset`.
- A pinned sample now reports `visible`. A pinned item is parked at the
  leading edge, so its unpinned local offset walks off screen while the host
  is still painting it; judging visibility on intersection alone dropped a
  section halfway through its own pin.
- `MotionPathViewportSample` compares by value, so the pin host rebuilds only
  when sampled geometry moves rather than once per scrolled pixel.
- Attach, detach, reattach, route teardown, and mid-scroll disposal are
  covered. Disposal stays terminal and reattaching a parked position seeds
  instead of replaying a crossing that never happened.

## Deliberate exclusions

- Snap stays deferred. No authored scene needs it yet, and interruption
  behavior has to be specified before an implementation is worth reviewing.
  This is an exclusion, not a gap.

## Exit evidence

- `scroll_pin_integration_test.dart` drives a real `ScrollPosition` through
  approach, pin, release, and reverse travel, asserting paint offsets,
  visibility, seeked progress, crossing order, and host teardown.
- `pinned_header_test.dart`, `scroll_binding_test.dart`,
  `scroll_reattach_test.dart`, `viewport_binding_test.dart`,
  `viewport_toggle_test.dart`, `viewport_lifecycle_test.dart`, and
  `route_lifecycle_test.dart` stay green.
- Phase 7 Carousel unblocks once this gate closes.
