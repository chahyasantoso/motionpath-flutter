# Audit implementation plan

Updated 2026-08-03 after the codebase audit and merges of PRs #146 and #147.

The goal is to remove release-relevant correctness risks without blocking independent release preparation. Code changes use separate PRs; documentation-only updates may land directly on `main`.

## Workstreams

### A. Runtime contract hardening, P0

Owner: core runtime.

- Reject duplicate observation edges in `MotionPathTrackRuntime.observe()`.
- Add focused tests for duplicate output edges, duplicate input edges, and valid distinct edges.
- Preserve insertion-order merge semantics for distinct output observations and document it.

Blocked by: none. This is the first code slice.

### B. Plugin payload validation, P0

Owner: core plugin boundary.

- Replace unsafe authored-anchor casts with finite numeric validation.
- Decide and document the malformed-path policy: strict validation at construction versus empty composition at runtime. Use one policy consistently.
- Add tests for malformed anchors, non-finite values, malformed nodes, and short paths.

Blocked by: the contract decision in this workstream. Can run in parallel with A once the policy is fixed.

### C. Public API inventory, P1

Owner: package/release tooling.

- Add a small test or script that compares public entrypoint exports with the API classification.
- Keep implementation files under `lib/src/` internal by convention and document intentional experimental exports.
- Add the result to the release checklist.

Blocked by: none. Can run in parallel with A and B.

### D. Spawn cache lifecycle, P1

Owner: Flutter adapter.

- Add controller replacement coverage.
- Add builder replacement coverage and decide whether builder changes invalidate cached children or require a stable builder contract.
- Keep the invariant wrapper and value-key behavior from PR #147.

Blocked by: none. Can run in parallel with A and B.

### E. Release evidence, P1

Owner: release hardening.

- Run clean-package analyze/test commands and retain logs.
- Complete parity inventory, package metadata/versioning, path dependency replacement, publish dry-runs, benchmark JSON, security scan, and generated-file hygiene.

Blocked by: A and B release decisions; the mechanical evidence work can start immediately.

## Recommended execution order

1. Implement A and B together in one focused core PR because both change boundary correctness and need the same fixture/test pass.
2. Implement C and D in a separate Flutter/release PR so API tooling and widget lifecycle coverage do not block core review.
3. Run E after both PRs are green, then update `RELEASE_CHECKLIST.md` with commit-specific evidence.

## Exit criteria

- No duplicate observation registration is silently accepted.
- Malformed plugin payloads fail consistently with actionable errors or produce the documented empty result, never an opaque cast error.
- Public exports have an automated or explicitly reviewed inventory.
- Spawn cache behavior under controller/builder replacement is tested and documented.
- Release checklist has reproducible command and artifact evidence.
