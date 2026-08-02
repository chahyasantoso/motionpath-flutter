# MotionPath Flutter session handoff

Updated 2026-08-02 after PR #115 merged green.

## Repo and workflow

- Repository: `chahyasantoso/motionpath-flutter`
- Work directly on `main` for docs-only changes. No PR and no tests required.
- Code changes: branch, open PR, wait for all four CI jobs, inspect logs when red, fix on the same branch, then merge green.
- Keep a running play-by-play in chat. The user explicitly wants each step narrated.

## Current phase state

- Phases 0 through 5: Complete.
- Phase 6 Cross-repository parity: Partial and near closeout. PRs #111 through #113 are merged; only the eased-overshoot divergence decision remains.
- Phase 7 Carousel: Active. PR #114 covers reverse scrubbing. PR #115 proves stable card subtrees and records the scoped per-card GlobalKey tradeoff. Next is overlap hit testing plus mid-chain reflow coverage.
- Phase 8 Helix/depth: Blocked until Phase 6 and Phase 7 mature.
- Phase 9 release hardening: Partial.

Authoritative closeout docs:

- `docs/PHASE_6_ACCEPTANCE.md`
- `docs/PHASE_7_ACCEPTANCE.md`
- `docs/PHASE_STATUS.md`
- `docs/COMPATIBILITY.md`

## Merged implementation slices

- #91: fixed default plugin registration and authored `path`/`imageSequence` payloads crossing the JSON boundary.
- #92: added path `autoRotate` tangent rotation.
- #93: added the scroll-driven Carousel example with shared patches, dynamic children, stagger, add/remove, and front-most hit testing.
- #94: added Carousel mount and real ListView scrubbing coverage; fixed transformed card text overflow.
- #95: parsed time triggers now autoplay by default; explicit pause, manual, and scroll semantics remain distinct.
- #96: added validation for malformed path and image payloads; fixed analyzer imports/lints before merge.
- #97: fixed repeat completion math so `repeat` means repeat count, including yoyo and repeat-delay boundaries.
- #98: path stop easing now applies before physical-distance sampling; fixed missing interpolation imports and preserved path stops for plain paths.
- #99: added path anchors: `center`, `none`, and explicit `{xPercent, yPercent}`; fixed payload carry-through and restored precise diagnostics.
- #100: matched JS path validation edge cases.
- #101: rejected path combined with explicit `x` or `y` at validation time.
- #102: added one-shot motion completion events with restart and seek-back re-arming.
- #103: locked reverse, play/pause, seek-back, completion, unmount, and destroy lifecycle coverage.
- #104: added Overlay and Spawner plugin edge coverage.
- #105: added ImageSequence stop type and frame-index validation.
- #106: added whole-timeline trajectory fixtures with exact key-set assertions.
- #107: added observation graph parity fixtures.
- #108: added the lifecycle parity fixture matrix.
- #109: added repeat, yoyo, delay, repeat delay, stagger, and completion fixtures.
- #110: added the malformed-project diagnostics matrix.
- #111: extracted the shared JSON fixture loader into `test/support/fixture_support.dart`.
- #112: added dedicated filter and CSS variable parity fixtures.
- #113: added the fixture index and metadata guard, including the fix for fixture-specific sample shapes.
- #114: added reverse-scroll coverage while preserving card identity and settled offsets.
- #115: proved stable card subtrees survive patch updates. The spawn view now caches each expensive child by instance id and uses a scoped per-card `GlobalKey` as the identity anchor.

## Next work, in order

### Phase 6 closeout

1. Resolve the eased-overshoot divergence candidate: confirm against JS, then fix the clamp or document it in `docs/COMPATIBILITY.md` with an owner and a regression test.
2. Close Phase 6 only when that decision and test are green or explicitly documented as excluded.

### Phase 7 Carousel closeout

1. Add overlapping-card front-most hit-test coverage tied to the actual spawn view.
2. Add mid-chain removal/reflow coverage and prove survivors do not teleport.
3. Add teardown coverage while cards are mounted and after the scroll host is disposed.
4. Add representative geometry assertions or a stable golden at progress 0, 0.15, 0.5, 0.85, and 1.
5. Add the shared JS scene builder/fixture and record intentional differences.
6. Close Phase 7 docs only after all acceptance items are green.

## Known sharp edges

- Path payloads keep points plus metadata such as stops, autoRotate, and anchor. If metadata is dropped in `propertiesFromTrack`, the plugin silently loses behavior.
- `path_plugin.dart` needs both `interpolation/interpolator.dart` and `interpolation/easing.dart` imports.
- Preserve existing test coverage when adding validation cases. Do not replace a whole test file with a reduced subset.
- Analyzer is strict and CI runs `dart analyze --format machine` plus all tests. Fix unused imports and curly-brace lint findings before waiting on CI.
- `repeat` is repeat count, so total cycles are `repeat + 1`; repeat delays occur only between cycles.
- Value interpolation clamps `t` to `[0, 1]`, so overshooting eases never overshoot. Avoid `back.*` and `elastic.*` in value fixtures until that is resolved.
- The Carousel does not use drain semantics. `drainOnComplete` belongs to Spiral-style scenes and must not leak into Carousel tests or docs.
- The stable card-subtree fix intentionally uses a per-card GlobalKey. A stable host/render-object design could avoid GlobalKey overhead, but that is a separate refactor, not a reason to destabilize the current green contract.
- Docs-only changes go straight to `main`; code changes need the full four-job gate.

## Session result

Phase 6 is near complete: plugin fixtures, shared loader tooling, and the fixture index are merged. Phase 7 now has reverse-scroll and stable subtree evidence, with the GlobalKey tradeoff documented. The next code slice is overlap hit testing plus mid-chain reflow, then teardown and geometry coverage.
