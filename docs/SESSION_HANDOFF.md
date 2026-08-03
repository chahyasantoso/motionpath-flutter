# MotionPath Flutter handoff

Updated 2026-08-03 after the full demo pass.

## Repository and workflow

- Repository: `chahyasantoso/motionpath-flutter`
- Docs-only changes go directly to `main`.
- Code changes use a branch and PR, then wait for all four CI jobs: `hygiene`, `dart-core`, `flutter-adapter`, `flutter-example`.
- If CI is red, use the supplied logs and fix on the same branch.

## Current state

- All nine JS demo routes are ported and covered: Carousel, Spiral/Zuma, Helix, Walker, Burst, Motorcycle, Pasar Malam, Pasar Malam Observer, Tower Defense, and Hooks Demo.
- The launcher exposes every completed demo. PR #143 has a green rerun after fixing offstage drawer assertions and drawer-transition timing; merge it when the branch is ready.
- Spiral now renders directly through `MotionPathSpawnView`; its manual per-ball patch-source plumbing is gone in PR #144.
- Pasar Malam uses an asset-free frame indicator instead of bundling the reference WebP sequence. The difference is documented in `docs/COMPATIBILITY.md`.
- Phase 9 Release hardening remains open.

## Next work

1. Merge PR #143 after its green rerun.
2. Run clean-package analysis and tests for core, Flutter adapter, and example.
3. Review public exports, API classifications, package metadata, and path dependencies.
4. Run `dart pub publish --dry-run` and `flutter pub publish --dry-run` after publish settings are ready.
5. Capture controlled benchmark JSON with commit SHA, environment, Dart version, and build mode.
6. Complete security, generated-file, and release-tag evidence.

## Source of truth

- `docs/DEMO_PORT_PLAN.md`
- `docs/PHASE_STATUS.md`
- `docs/COMPATIBILITY.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/API_SURFACE.md`
- `docs/SESSION_HANDOFF.md`
