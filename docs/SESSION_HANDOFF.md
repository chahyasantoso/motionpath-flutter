# MotionPath Flutter handoff

Updated 2026-08-03 after PRs #146 through #149 merged green.

## Repository and workflow

- Repository: `chahyasantoso/motionpath-flutter`
- Docs-only changes go directly to `main`.
- Code changes use a branch and PR, then wait for all four CI jobs: `hygiene`, `dart-core`, `flutter-adapter`, `flutter-example`.
- If CI is red, use the supplied logs and fix on the same branch.

## Current state

- All ten completed demo routes are ported, covered, and reachable from the launcher.
- PRs #143, #144, #146, #147, #148, and #149 are merged green.
- Spiral/Zuma uses the generic spawn renderer; endpoint resampling and launcher timing regressions are covered.
- Spawn child identity uses namespaced value keys and an invariant wrapper tree; cache replacement is covered.
- Runtime duplicate-observation and malformed path/anchor payload hardening is complete.
- Publishing and release hardening are deferred until further notice.
- PR #150 is intentionally unmerged and reserved for a future publishing pass.

## Next work

1. No audit implementation work remains; workstreams A through D are complete.
2. Do not merge PR #150 or run publish dry-runs, tagging, or release benchmark capture until publishing is reactivated.
3. When reactivated, review PR #150, rerun clean-package checks from the resulting commit, and resume the release checklist.

## Source of truth

- `docs/DEMO_PORT_PLAN.md`
- `docs/PHASE_STATUS.md`
- `docs/COMPATIBILITY.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/API_SURFACE.md`
- `docs/CODEBASE_AUDIT.md`
- `docs/AUDIT_IMPLEMENTATION_PLAN.md`
- `docs/SESSION_HANDOFF.md`
