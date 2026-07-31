# Phase status

Updated 2026-07-31 against `main` after the green CI gates.

| Phase | Status | Evidence | Gate |
|---|---|---|---|
| 0 Baseline and guardrails | Complete | PR #66 merged; all CI jobs passed. | Closed |
| 1 Lifecycle ownership | Complete | PR #68 merged; all CI jobs passed. | Closed |
| 2 Immutable patch contract | Complete | PR #69 and PR #71 merged; interest-scoped composition, key taxonomy, normalizer, immutability tests, plugin coverage, and contract docs are complete. | Closed |
| 3 Shared Flutter renderer | **Ready to close** | PRs #73 through #79 merged: shared payload consumption, stable child rendering, interest-scoped consumers, bounded filters, z/perspective/3D transforms, image cache lifecycle, performance coverage, Spiral migration, and explicit renderer key policy. | Close after this PR is green and merged |
| 4 Dynamic children and spawn lifecycle | Partial | Existing spawn/reflow implementation is covered, but ordering and demo duplication remain. | Do not mark complete until its own gate closes |
| 5 Scroll capabilities | Partial | Scrub, viewport sampling, toggle actions, and top pinning exist. | Arbitrary pinning remains open; snap deferred |
| 6 Cross-repository parity | Partial | Initial JS fixtures plus plugin contract coverage pass. | Broader lifecycle, trigger, path, FK, trajectory, and diagnostics fixtures remain |
| 7 Carousel | Not started | No Carousel implementation. | Blocked until Phase 3 closes |
| 8 Helix and depth | Not started | No Helix/depth renderer. | Blocked until Phase 3 closes |
| 9 Release hardening | Partial | Docs, metadata, CI, and benchmark harness exist. | Publish/security/API-doc evidence remains |

## Operating rule

A phase is complete only after its PR is green, merged into `main`, and its exit criteria are recorded here and in the implementation plan. Partial work stays partial.
