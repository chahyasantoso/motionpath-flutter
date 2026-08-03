# Codebase audit

Updated 2026-08-03 after PRs #146 and #147 merged green.

## Scope

Reviewed the public entrypoints, runtime ownership, composition, plugin boundaries, Flutter controllers and hosts, CI workflow, package manifests, tests, examples, and release documentation. This is a source review; it is not a substitute for the clean-package command matrix in `RELEASE_CHECKLIST.md`.

## Findings

### P0 release blockers

1. **Release metadata is intentionally unfinished.** Both packages remain unpublished, the Flutter package uses a local path dependency, and versions/changelog entries are not release-ready. Keep this as release work, not a code shortcut.
2. **The clean-package gate is still missing.** CI is green on the merged PRs, but the release commit still needs clean package analysis/tests, publish dry-runs, and retained evidence.
3. **Parity coverage is broader than the original plan but not complete proof.** Treat fixture coverage as an explicit inventory. Missing or weak areas must be listed before publishing rather than inferred from demo coverage.

### P1 correctness and maintainability

4. **Input validation is uneven at plugin boundaries.** `path_plugin.dart` skips malformed points, while `_anchorPatch` uses forced numeric casts for authored anchor values. A malformed payload can therefore be silently dropped in one path and throw an opaque cast error in another. Proposal: validate plugin payloads once at the contract boundary, return structured diagnostics, and make runtime composition consume only validated values.
5. **Observation ownership is safe but duplicate semantics are under-specified.** `observe()` validates role/input shape, but duplicate edges from the same source can still be registered. Proposal: reject duplicate `(source, role, input)` edges and document whether distinct output edges are merged in insertion order.
6. **Public export review needs an automated guard.** The entrypoints export several experimental adapters by design, but the stable/experimental/internal classification is maintained manually. Proposal: add an API-surface test or generated export inventory so accidental public exposure fails CI.
7. **Widget identity is now structurally correct, but the cache contract deserves a focused test.** `MotionPathSpawnView` caches built child widgets by instance id and prunes them on controller notifications. Keep the invariant wrapper test and add coverage for controller replacement and builder replacement before making the adapter stable.
8. **Some hot paths allocate avoidable temporary collections.** Graph composition, depth ordering, and path sampling create lists/maps per update. This is acceptable for current demos, but benchmark before optimizing. Proposal: measure 14, 50, and 250 tracks first, then optimize only allocations shown in the profile.

### P2 cleanup opportunities

9. **Docs had drifted from the shipped state.** The old parity implementation plan described pre-Carousel and pre-Helix work as future work and conflicted with `PHASE_STATUS.md`; it has been removed. The current source of truth is the phase table, release checklist, compatibility policy, and this audit.
10. **Demo coverage can create false confidence.** A launcher test proves routes mount, not that every route consumes composed patches correctly. Keep scene-contract and lifecycle tests as the release evidence, and do not replace them with screenshot-only checks.

## Recommended order

1. Land the validation and duplicate-observation fixes with focused tests.
2. Add an export inventory check and cache lifecycle coverage.
3. Run clean-package analysis/tests and the remaining parity matrix.
4. Pin release versions, replace the Flutter path dependency, run publish dry-runs, capture benchmark JSON, and complete security/generated-file checks.
5. Tag only from the fully green release commit.

## Non-findings

- The former `GlobalKey` registry was a real workaround for an unstable conditional wrapper tree. PR #147 fixes the cause with stable value keys and invariant wrappers.
- The Spiral RangeError was a bounded resampling bug, not evidence that the spawn controller needed another identity mechanism. PR #146 fixes the endpoint clamp and launcher timing test.
- A second animation framework is not warranted. The dependency decision to keep core pure Dart and use Flutter primitives remains sound.
