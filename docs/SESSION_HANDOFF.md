# MotionPath Flutter handoff

Updated 2026-08-03 after the audit implementation plan was recorded.

## Repository and workflow

- Repository: `chahyasantoso/motionpath-flutter`
- Docs-only changes go directly to `main`.
- Code changes use a branch and PR, then wait for all four CI jobs: `hygiene`, `dart-core`, `flutter-adapter`, `flutter-example`.
- If CI is red, use the supplied logs and fix on the same branch.

## Current state

- All ten completed demo routes are ported, covered, and reachable from the launcher.
- PRs #143, #144, #146, and #147 are merged.
- Spiral/Zuma uses the generic spawn renderer; endpoint resampling and launcher timing regressions are covered.
- Spawn child identity uses namespaced value keys and an invariant wrapper tree; the former GlobalKey registry is gone.
- The codebase audit and parallel implementation plan are recorded in `docs/CODEBASE_AUDIT.md` and `docs/AUDIT_IMPLEMENTATION_PLAN.md`.
- Phase 9 release hardening remains open.

## Next work

1. Implement workstreams A and B in the core runtime/plugin PR.
2. Implement workstreams C and D in the adapter/release PR.
3. Start workstream E immediately: clean-package checks, parity inventory, metadata, publish dry-runs, benchmark, security, and generated-file evidence.
4. Update this handoff and `RELEASE_CHECKLIST.md` with commit-specific evidence after each green PR.

## Source of truth

- `docs/DEMO_PORT_PLAN.md`
- `docs/PHASE_STATUS.md`
- `docs/COMPATIBILITY.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/API_SURFACE.md`
- `docs/CODEBASE_AUDIT.md`
- `docs/AUDIT_IMPLEMENTATION_PLAN.md`
- `docs/SESSION_HANDOFF.md`
