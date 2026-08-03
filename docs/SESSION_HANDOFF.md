# MotionPath Flutter handoff

Updated 2026-08-03 after PRs #146 and #147 merged green.

## Repository and workflow

- Repository: `chahyasantoso/motionpath-flutter`
- Docs-only changes go directly to `main`.
- Code changes use a branch and PR, then wait for all four CI jobs: `hygiene`, `dart-core`, `flutter-adapter`, `flutter-example`.
- If CI is red, use the supplied logs and fix on the same branch.

## Current state

- All ten completed demo routes are ported, covered, and reachable from the launcher.
- PR #143 is merged, PR #144 is merged, PR #146 is merged, and PR #147 is merged.
- Spiral/Zuma uses the generic spawn renderer. Its endpoint resampling and launcher timing regressions are covered.
- Spawn child identity uses namespaced value keys and an invariant wrapper tree; the former GlobalKey registry is gone.
- Pasar Malam intentionally uses an asset-free frame indicator; the difference is documented in `docs/COMPATIBILITY.md`.
- Phase 9 Release hardening remains open.

## Next work

1. Read `docs/CODEBASE_AUDIT.md` and decide whether the P1 validation and duplicate-observation items land before release.
2. Run clean-package analysis/tests for core, Flutter adapter, and example from the release candidate commit.
3. Review exports, API classifications, package metadata, and path dependencies.
4. Run `dart pub publish --dry-run` and `flutter pub publish --dry-run` after release settings are ready.
5. Capture controlled benchmark JSON with commit SHA, environment, Dart version, and build mode.
6. Complete security, generated-file, changelog, and release-tag evidence.

## Source of truth

- `docs/DEMO_PORT_PLAN.md`
- `docs/PHASE_STATUS.md`
- `docs/COMPATIBILITY.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/API_SURFACE.md`
- `docs/CODEBASE_AUDIT.md`
- `docs/SESSION_HANDOFF.md`
