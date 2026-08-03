# Release checklist

This repository is not publish-ready until every item below is checked on the release commit.

## Contract and compatibility

- [ ] Confirm `schemaVersion: 4` fixtures against the JavaScript reference.
- [ ] Run Dart and Flutter analysis and tests from clean package directories.
- [ ] Review fatal and warning diagnostics for representative invalid projects.
- [ ] Verify graph ordering, diamond composition, cycles, FK, triggers, plugins, scroll, viewport, and dynamic child behavior against fixtures.
- [ ] Resolve the validation and duplicate-observation findings in `docs/CODEBASE_AUDIT.md` or record an explicit release decision.

## API and package metadata

- [ ] Review every export in both public library entrypoints.
- [x] Classify stable, experimental, and internal APIs in `docs/API_SURFACE.md`.
- [ ] Add an automated export inventory check or record why the manual review is sufficient.
- [ ] Replace path dependency with the published core version in the Flutter package before publishing.
- [ ] Set the release version and update `CHANGELOG.md`.
- [ ] Run `dart pub publish --dry-run` for the core package.
- [ ] Run `flutter pub publish --dry-run` for the Flutter package.
- [ ] Confirm repository, issue tracker, and documentation links in both package manifests.

## Flutter integration

- [ ] Exercise ticker startup, stop, disposal, and shared-ticker spawn binding.
- [ ] Exercise scroll detach/reattach and viewport route teardown.
- [x] Render a pinned viewport item and a dynamic spawn chain in the test/example suites.
- [ ] Add controller replacement and builder replacement coverage for cached spawn children.
- [ ] Confirm image, CSS-variable, filter, Overlay, and Spawner host consumers.

## Performance and release hygiene

- [ ] Record controlled benchmark JSON with commit SHA, OS, CPU, Dart version, and build mode.
- [ ] Review analyzer output with strict casts, inference, and raw types.
- [ ] Confirm no generated files, credentials, or machine-local benchmark output are committed.
- [ ] Tag the release commit only after CI is green.
- [ ] Publish core and Flutter packages separately, in that order.

## Phase evidence already on `main`

- [x] Phase 6 parity closeout, including eased overshoot regression coverage, PR #123.
- [x] Phase 7 Carousel closeout, PRs #121 and #122.
- [x] Phase 8 Helix/depth closeout, PRs #124 through #126.
- [x] Launcher exposes Spiral/Zuma and endpoint resampling is covered, PR #146.
- [x] Spawn identity no longer depends on a global key registry, PR #147.
- [x] Code smell and stale-document audit recorded in `docs/CODEBASE_AUDIT.md`.
- [x] Parallel implementation plan recorded in `docs/AUDIT_IMPLEMENTATION_PLAN.md`.

## Active implementation plan

See `docs/AUDIT_IMPLEMENTATION_PLAN.md` for workstreams A through E, dependencies, and exit criteria.

## Explicit non-goals

Do not claim DOM, GSAP, React, CSS, or browser-layout source parity. Claim behavioral compatibility at the v4 contract, runtime, patch, and lifecycle boundaries only.
