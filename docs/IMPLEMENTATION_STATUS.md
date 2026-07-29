# Implementation status

## Phase 0

The repository now has separate pure-Dart and Flutter package boundaries, shared documentation, and CI jobs for each package.

## Phase 1 starting point

The public contract currently exposes a minimal `MotionPathProject` schema-version type. The next implementation slice must add JSON parsing, structured diagnostics, and collect-all validation before runtime objects exist.

This file is intentionally blunt: the current adapter classes are scaffolding, not a production engine.
