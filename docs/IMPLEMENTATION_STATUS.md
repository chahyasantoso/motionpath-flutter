# Implementation status

Audited against merged pull requests and current CI, not memory. The authoritative phase-by-phase table is [`PHASE_STATUS.md`](PHASE_STATUS.md), and the detailed execution plan is [`FLUTTER_PARITY_IMPLEMENTATION_PLAN.md`](FLUTTER_PARITY_IMPLEMENTATION_PLAN.md).

## Current gates

- **Phase 0: complete.** PR #66 merged after hygiene, Dart core, Flutter adapter, and example CI jobs passed.
- **Phase 1: complete.** PR #68 merged after lifecycle ownership and runtime-boundary tests passed across the same CI matrix.
- **Phase 2: active.** The current branch adds optional interest-scoped composition while preserving full-graph behavior. The remaining immutable patch contract tasks are still open and must be completed before Phase 3.
- **Phase 3 and later: blocked.** Existing renderer, spawn, scroll, parity, Carousel, Helix, and release work remains partial or not started as recorded in `PHASE_STATUS.md`.

## Completed implementation history

The repository contains the earlier merged work for the v4 contract, collect-all validation, observation graph compiler, pure Dart runtime, trigger math, interpolation, renderer-neutral patches, forward kinematics, scroll bindings, authored easing and colors, Walker scene rendering, plugin contracts, path/image/CSS/filter/scene plugins, benchmarks, patch consumers, lifecycle-safe ticker/viewport bindings, layout policy, spawn/reflow, pinning, canonical fixtures, Spiral/Zuma, and JS-backed parity fixtures.

## Operating rule

A phase is not complete because a slice exists. Mark it complete only after the phase PR is green, merged into `main`, and its exit criteria are recorded in both status documents. Do not advance to the next phase while the current phase is partial.
