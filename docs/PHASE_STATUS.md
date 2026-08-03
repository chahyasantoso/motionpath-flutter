# Phase status

Updated 2026-08-03 against `main` after PRs #146 and #147 merged green.

| Phase | Status | Evidence | Gate |
|---|---|---|---|
| 0 Baseline and guardrails | Complete | PR #66 merged; all CI jobs passed. | Closed |
| 1 Lifecycle ownership | Complete | PR #68 merged; all CI jobs passed. | Closed |
| 2 Immutable patch contract | Complete | PR #69 and PR #71 merged; interest-scoped composition, key taxonomy, normalizer, immutability tests, plugin coverage, and contract docs are complete. | Closed |
| 3 Shared Flutter renderer | Complete | PRs #73 through #80 merged; shared payload consumption, stable child rendering, interest-scoped consumers, bounded filters, z/perspective/3D transforms, image cache lifecycle, performance coverage, Spiral migration, explicit renderer key policy, and green CI are complete. | Closed |
| 4 Dynamic children and spawn lifecycle | Complete | PRs #81 through #86 and #147 merged; deterministic ordering, invariant wrapper identity, front-most hit testing, reflow/drain, lifecycle coverage, and reusable spawn rendering are complete. | Closed |
| 5 Scroll capabilities | Complete | PR #88 and PR #89 merged; scrub sampling, toggle actions, top pinning, arbitrary pinning, visibility, value equality, and real ScrollPosition integration coverage are complete. | Closed. Snap remains deliberately deferred |
| 6 Cross-repository parity | Complete | PRs #91 through #113 cover parity behavior, diagnostics, plugin fixtures, shared fixture tooling, and fixture-index enforcement. PR #123 resolves eased overshoot against the JavaScript reference with dedicated regression coverage. | Closed |
| 7 Carousel | Complete | PRs #93, #94, and #114 through #122 cover mount/scrub, reverse scroll, stable subtrees, overlap hit testing, reflow, teardown, representative geometry, the shared scene contract, the demo, and host interaction coverage. | Closed |
| 8 Helix and depth | Complete | PRs #124 through #126 cover generic z-depth ordering, Matrix4 rendering, the shared Helix scene contract, sampled trajectories, and the real Helix demo host with widget coverage. | Closed |
| 9 Release hardening | Partial | PRs #146 and #147 close the launcher and spawn identity gaps. The codebase audit is recorded in `docs/CODEBASE_AUDIT.md`. | Open |

## Operating rule

A phase is complete only after its PR is green, merged into `main`, and its exit criteria are recorded here. Partial work stays partial.
