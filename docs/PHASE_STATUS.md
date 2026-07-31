# Phase status

Updated 2026-07-31 against `main` after the green CI gates.

| Phase | Status | Evidence | Gate |
|---|---|---|---|
| 0 Baseline and guardrails | Complete | PR #66 merged; hygiene, Dart core, Flutter adapter, and example CI jobs passed. | Closed |
| 1 Lifecycle ownership | Complete | PR #68 merged; lifecycle ownership, malformed observations, invalid graph rejection, duplicate IDs, finite runtime boundaries, and disposal tests passed in CI. | Closed |
| 2 Immutable patch contract | Active | Phase 2 branch adds optional interest-scoped composition and regression coverage while preserving full-graph semantics. | Must finish all Phase 2 tasks and pass CI before Phase 3 |
| 3 Shared Flutter renderer | Not started | Existing renderer slice remains partial. | Blocked by Phase 2 |
| 4 Dynamic children and spawn lifecycle | Partial | Existing spawn/reflow implementation is covered, but ordering and demo duplication remain. | Do not advance until Phase 3/4 gates are explicitly closed |
| 5 Scroll capabilities | Partial | Scrub, viewport sampling, toggle actions, and top pinning exist. | Arbitrary pinning remains open; snap deferred |
| 6 Cross-repository parity | Partial | Initial JS fixtures pass for five cases. | Broader lifecycle, trigger, plugin, path, FK, and diagnostic fixtures remain |
| 7 Carousel | Not started | No Carousel implementation. | Blocked until Phase 2 and 3 are complete |
| 8 Helix and depth | Not started | No Helix/depth renderer. | Blocked until shared renderer is complete |
| 9 Release hardening | Partial | Docs, metadata, CI, and benchmark harness exist. | Publish/security/API-doc evidence remains |

## Operating rule

A phase is only marked complete after its PR is green, merged into `main`, and its exit criteria are recorded here and in the implementation plan. Partial work stays partial. No later phase is treated as complete because an earlier slice exists.
