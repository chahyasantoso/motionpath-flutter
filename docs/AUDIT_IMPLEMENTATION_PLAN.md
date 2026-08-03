# Audit implementation plan

Updated 2026-08-03 after PRs #146 through #149 merged green.

The goal is to remove release-relevant correctness risks without blocking independent release preparation. Code changes use separate PRs; documentation-only updates may land directly on `main`.

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
- Add generated export automation when release tooling is introduced. Until then, the manual review is the explicit release decision.

### D. Spawn cache lifecycle, P1

Status: **complete in PR #149**.

- Cached spawn children are cleared when the controller changes.
- Cached spawn children are cleared when the item builder changes, preventing stale host closures from surviving.
- Invariant wrapper and value-key behavior from PR #147 remain intact.
- Controller replacement and builder replacement coverage is green.

### E. Release evidence, P1

Status: **active**.

- Run clean-package analyze/test commands and retain logs.
- Complete parity inventory, package metadata/versioning, path dependency replacement, publish dry-runs, benchmark JSON, security scan, and generated-file hygiene.

## Recommended execution order

1. PRs #148 and #149 are merged and their four-job CI matrices are green.
2. Run the clean-package matrix from the current `main` tip and retain commit-specific artifacts.
3. Finish package metadata, publish dry-runs, benchmark, security, and generated-file evidence in parallel where possible.
4. Update `RELEASE_CHECKLIST.md` with commit-specific evidence, then tag only from the fully green release commit.

## Exit criteria

- No duplicate observation registration is silently accepted. **Met by PR #148.**
- Malformed plugin payloads fail consistently with actionable errors or produce the documented empty result, never an opaque cast error. **Met by PR #148.**
- Public exports have an automated or explicitly reviewed inventory. **Manual review met; automation deferred.**
- Spawn cache behavior under controller/builder replacement is tested and documented. **Met by PR #149.**
- Release checklist has reproducible command and artifact evidence. **Pending.**
