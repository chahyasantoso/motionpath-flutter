# Phase status

Updated 2026-08-03 against `main` after PR #134 merged green.

| Phase | Status | Evidence | Gate |
|---|---|---|---|
| 0 Baseline and guardrails | Complete | PR #66 merged; all CI jobs passed. | Closed |
| 1 Lifecycle ownership | Complete | PR #68 merged; all CI jobs passed. | Closed |
| 2 Immutable patch contract | Complete | PR #69 and PR #71 merged; interest-scoped composition, key taxonomy, normalizer, immutability tests, plugin coverage, and contract docs are complete. | Closed |
| 3 Shared Flutter renderer | Complete | PRs #73 through #80 merged; shared payload consumption, stable child rendering, interest-scoped consumers, bounded filters, z/perspective/3D transforms, image cache lifecycle, performance coverage, Spiral migration, explicit renderer key policy, and green CI are complete. | Closed |
| 4 Dynamic children and spawn lifecycle | Complete | PRs #81 through #86 merged; deterministic ordering, host paint order, front-most hit testing, reflow/drain, lifecycle coverage, and Spiral rebuild cleanup are complete. | Closed |
| 5 Scroll capabilities | Complete | PR #88 and PR #89 merged; scrub sampling, toggle actions, top pinning, arbitrary pinning, visibility, value equality, and real ScrollPosition integration coverage are complete. | Closed. Snap remains deliberately deferred |
| 6 Cross-repository parity | Complete | PRs #91 through #113 cover parity behavior, diagnostics, plugin fixtures, shared fixture tooling, and fixture-index enforcement. PR #123 resolves eased overshoot against the JavaScript reference with dedicated regression coverage. | Closed |
| 7 Carousel | Complete | PRs #93, #94, and #114 through #122 cover mount/scrub, reverse scroll, stable subtrees, overlap hit testing, reflow, teardown, representative geometry, the shared scene contract, the demo consuming that scene, host interaction coverage for forward scroll, reverse scroll, add, and re-entry, host opacity assertions against the authored stops, and the stage guide derived from the shared scene. Intentional Flutter/JS differences are recorded in `docs/COMPATIBILITY.md`. | Closed |
| 8 Helix and depth | Complete | PRs #124 through #126 cover generic z-depth ordering, Matrix4 rendering, the shared Helix scene contract, sampled trajectories, and the real Helix demo host with widget coverage. Intentional Flutter/JS differences are recorded in `docs/PHASE_8_ACCEPTANCE.md`. | Closed |
| 9 Release hardening | Partial | Docs, metadata, CI, benchmark harness, and the complete JS demo port inventory exist. Walker, Burst, and Motorcycle are now ported and green: PRs #127 through #132 and #134. Remaining demo ports, the demo launcher, and publish/security/API-doc evidence are tracked in `docs/DEMO_PORT_PLAN.md` and `docs/RELEASE_CHECKLIST.md`. | Open |

## Operating rule

A phase is complete only after its PR is green, merged into `main`, and its exit criteria are recorded here and in the implementation plan. Partial work stays partial.
