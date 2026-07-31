# Phase status

Updated 2026-07-31 against `main` after the green CI gates.

| Phase | Status | Evidence | Gate |
|---|---|---|---|
| 0 Baseline and guardrails | Complete | PR #66 merged; all CI jobs passed. | Closed |
| 1 Lifecycle ownership | Complete | PR #68 merged; all CI jobs passed. | Closed |
| 2 Immutable patch contract | Complete | PR #69 and PR #71 merged; interest-scoped composition, key taxonomy, normalizer, immutability tests, plugin coverage, and contract docs are complete. | Closed |
| 3 Shared Flutter renderer | **Complete** | PRs #73 through #80 merged; shared payload consumption, stable child rendering, interest-scoped consumers, bounded filters, z/perspective/3D transforms, image cache lifecycle, performance coverage, Spiral migration, explicit renderer key policy, and green CI are complete. | Closed |
| 4 Dynamic children and spawn lifecycle | Active | Spawn/reflow/drain implementation exists. This branch adds deterministic top-most-first ordering and stack paint-order coverage. | Open. Must finish ordering, hit testing, and demo/lifecycle cleanup before Phase 5 |
| 5 Scroll capabilities | Partial | Scrub, viewport sampling, toggle actions, and top pinning exist. | Arbitrary pinning remains open; snap deferred |
| 6 Cross-repository parity | Partial | Initial JS fixtures plus plugin contract coverage pass. | Broader lifecycle, trigger, path, FK, trajectory, and diagnostics fixtures remain |
| 7 Carousel | Not started | No Carousel implementation. | Blocked until Phase 4 is complete |
| 8 Helix and depth | Not started | No Helix/depth renderer. | Blocked until shared renderer is complete |
| 9 Release hardening | Partial | Docs, metadata, CI, and benchmark harness exist. | Publish/security/API-doc evidence remains |

## Operating rule

A phase is complete only after its PR is green, merged into `main`, and its exit criteria are recorded here and in the implementation plan. Partial work stays partial.
