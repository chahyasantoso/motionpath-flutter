# Phase 0 baseline

This file defines the reproducible baseline for the Flutter parity port. CI runs the required analysis, test, and repository-hygiene checks on every push and pull request; logs are retained as build artifacts so results are tied to an exact commit, SDK channel, and test environment.

## Required checks

| Surface | Commands | Expected result |
|---|---|---|
| Core analysis | `dart analyze --format machine` | zero issues |
| Core tests | `dart test --reporter expanded` | all tests pass |
| Flutter analysis | `flutter analyze` | zero issues |
| Flutter tests | `flutter test --reporter expanded` | all tests pass |
| Example analysis | `flutter analyze` | zero issues |
| Example tests | `flutter test --reporter expanded` | all tests pass |
| Generated-file hygiene | `bash tool/verify_generated_files.sh` | no tracked build or undeclared generated files |

Formatting is intentionally not a Phase 0 gate. Dart formatter output can vary across SDK releases, while analysis and tests are the behavioral guardrails that matter here. If formatting is standardized later, pin the SDK version first and add it as a separate, explicitly versioned maintenance check.

## Phase gate workflow

Every implementation phase lands through a pull request. The PR must target `main`, run the complete CI matrix above, and retain analyzer/test logs as artifacts. Phase 0 is complete only when this verification PR is green, its required checks are visible on GitHub, and the retained artifacts confirm the exact commit, SDK channel, and test results.

Do not merge a red or incomplete PR, and do not start Phase 1 until this PR passes all jobs. If CI fails, fix the branch and rerun the same PR rather than bypassing the gate with a direct push to `main`.

## How to capture a baseline locally

Run the commands from the package directories shown in `.github/workflows/ci.yml`. Save stdout and stderr with the commit SHA, Dart/Flutter versions, operating system, and build mode. CI is the canonical capture path because it runs the same commands on a clean checkout.

Do not call Phase 0 complete until one full CI run passes all required checks and its logs are retained against the commit that introduced the guardrails. Do not advance the implementation plan while this gate is open.
