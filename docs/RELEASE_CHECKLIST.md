# Release checklist

This repository is not publish-ready until every item below is checked on the
release commit.

## Contract and compatibility

- [ ] Confirm `schemaVersion: 4` fixtures against the JavaScript reference.
- [ ] Run Dart and Flutter analysis and tests from clean package directories.
- [ ] Review fatal and warning diagnostics for representative invalid projects.
- [ ] Verify graph ordering, diamond composition, cycles, FK, triggers, plugins,
      scroll, viewport, and dynamic child behavior against fixtures.

## API and package metadata

- [ ] Review every export in both public library entrypoints.
- [ ] Decide which APIs are stable, experimental, or internal before removing
      `publish_to: none`.
- [ ] Replace path dependency with the published core version in the Flutter
      package before publishing.
- [ ] Set the release version and update `CHANGELOG.md`.
- [ ] Run `dart pub publish --dry-run` for the core package.
- [ ] Run `flutter pub publish --dry-run` for the Flutter package.
- [ ] Confirm repository, issue tracker, and documentation links.

## Flutter integration

- [ ] Exercise ticker startup, stop, disposal, and shared-ticker spawn binding.
- [ ] Exercise scroll detach/reattach and viewport route teardown.
- [ ] Render a pinned viewport item and a dynamic spawn chain in one example.
- [ ] Confirm image, CSS-variable, filter, Overlay, and Spawner host consumers.

## Performance and release hygiene

- [ ] Record controlled benchmark JSON with commit SHA, OS, CPU, Dart version,
      and build mode.
- [ ] Review analyzer output with strict casts, inference, and raw types.
- [ ] Confirm no generated files, credentials, or machine-local benchmark output
      are committed.
- [ ] Tag the release commit only after CI is green.
- [ ] Publish core and Flutter packages separately, in that order.

## Explicit non-goals

Do not claim DOM, GSAP, React, CSS, or browser-layout source parity. Claim
behavioral compatibility at the v4 contract, runtime, patch, and lifecycle
boundaries only.
