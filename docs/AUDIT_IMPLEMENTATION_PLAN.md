# Audit implementation plan

Updated 2026-08-03 after PRs #146 through #149 merged green.

The goal was to remove release-relevant correctness risks without blocking independent release preparation. Code workstreams A through D are complete. Publishing and release evidence are explicitly deferred until further notice.

## Workstreams

### A. Runtime contract hardening, P0

Status: **complete in PR #148**.

- Duplicate observation edges are rejected while distinct output/input edges retain insertion-order merge semantics.
- Focused duplicate and distinct-edge regression coverage is green.

### B. Plugin payload validation, P0

Status: **complete in PR #148**.

- Authored anchors require finite numeric values before use.
- Malformed and non-finite path nodes are ignored consistently, including short-path handling.
- Focused malformed payload regression coverage is green.

### C. Public API inventory, P1

Status: **manual review complete; automation deferred**.

- Both public entrypoints were reviewed against `docs/API_SURFACE.md`.
- Intentional experimental adapters remain exported; implementation details remain under `lib/src/`.
- Generated export automation is deferred as a release-tooling improvement.

### D. Spawn cache lifecycle, P1

Status: **complete in PR #149**.

- Cached spawn children are cleared when the controller changes.
- Cached spawn children are cleared when the item builder changes, preventing stale host closures from surviving.
- Invariant wrapper and value-key behavior from PR #147 remain intact.
- Controller replacement and builder replacement coverage is green.

### E. Release evidence, P1

Status: **deferred until further notice**.

The following work is intentionally paused and must not be represented as complete:

- clean-package release-candidate evidence
- package metadata changes and path-dependency replacement
- publish dry-runs
- benchmark capture for release evidence
- release security review and tagging

PR #150 contains package metadata changes for a future publishing pass. It remains unmerged while publishing is deferred.

## Current conclusion

All audit implementation work is complete. No additional audit code PR is currently required. Resume workstream E only when publishing is explicitly reactivated.
