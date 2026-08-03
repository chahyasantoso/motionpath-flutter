# Audit implementation plan

Updated 2026-08-03 after the codebase audit and merges of PRs #146 and #147.

The goal is to remove release-relevant correctness risks without blocking independent release preparation. Code changes use separate PRs; documentation-only updates may land directly on `main`.

## Workstreams

### A. Runtime contract hardening, P0

Status: **in PR #148**.

- Reject duplicate observation edges in `MotionPathTrackRuntime.observe()`.
- Add focused tests for duplicate output edges, duplicate input edges, and valid distinct edges.
- Preserve insertion-order merge semantics for distinct output observations and document it.

### B. Plugin payload validation, P0

Status: **in PR #148**.

- Replace unsafe authored-anchor casts with finite numeric validation.
- Ignore malformed or non-finite path nodes consistently instead of allowing opaque cast errors.
- Add tests for malformed anchors, non-finite values, malformed nodes, and short paths.

### C. Public API inventory, P1

Status: **manual review complete; automation deferred**.

- Reviewed both public entrypoints against `docs/API_SURFACE.md`.
- Intentional experimental adapters remain exported; implementation details remain under `lib/src/`.
- Add a generated export inventory when release tooling is introduced. Until then, the manual review is the explicit release decision.

### D. Spawn cache lifecycle, P1

Status: **in PR #149**.

- Clear cached spawn children when the controller changes.
- Clear cached spawn children when the item builder changes, preventing stale host closures from surviving.
- Keep the invariant wrapper and value-key behavior from PR #147.
- Add controller replacement and builder replacement coverage.

### E. Release evidence, P1

Status: **pending; can run in parallel**.

- Run clean-package analyze/test commands and retain logs.
- Complete parity inventory, package metadata/versioning, path dependency replacement, publish dry-runs, benchmark JSON, security scan, and generated-file hygiene.

## Recommended execution order

1. Land PR #148 and PR #149 after all four CI jobs are green.
2. Start E immediately from the current main tip; do not wait for the code PRs for mechanical evidence gathering.
3. Re-run the clean-package matrix after both PRs merge.
4. Update `RELEASE_CHECKLIST.md` with commit-specific evidence, then tag only from the fully green release commit.

## Exit criteria

- No duplicate observation registration is silently accepted.
- Malformed plugin payloads fail consistently with actionable errors or produce the documented empty result, never an opaque cast error.
- Public exports have an automated or explicitly reviewed inventory.
- Spawn cache behavior under controller/builder replacement is tested and documented.
- Release checklist has reproducible command and artifact evidence.
