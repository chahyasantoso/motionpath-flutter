# JS to Flutter path parity plan

## Goal
Make the Flutter implementation match the original JavaScript MotionPath behavior for curved paths, constant-speed travel, and the Spiral/Zuma lifecycle.

## Phase 38: path model and sampling
- Support path nodes `{x, y, z?, ctrlX?, ctrlY?, ctrlZ?}`.
- Elevate quadratic controls to cubic Bézier segments, matching the JS reference.
- Build an arc-length lookup table and sample by normalized physical distance, not point index.
- Emit `x`, `y`, and `z`; keep rotation/anchor behavior as a follow-up once renderer contracts are aligned.
- Add core tests for controls, z, malformed nodes, and constant-distance sampling.

## Phase 39: spiral geometry parity
- Port the JS high-resolution Archimedean spiral generator.
- Re-sample raw points by cumulative length into uniformly spaced points.
- Derive travel duration and spawn interval from physical path length, ball speed, and ball size.
- Replace the Flutter example's low-resolution uniform-parameter spiral.

## Phase 40: spawn lifecycle parity
- Make completion observable or provide a deterministic drain callback.
- Ensure completed balls are removed without relying on `liveCount == 0`.
- Keep respawning independent from survivor reflow so one survivor cannot stall the stream.
- Add controller tests covering continuous respawn, completion, and reflow.

## Phase 41: visual and regression validation
- Add golden/trajectory assertions against reference JS sample points.
- Run package and example analyzer/tests in CI.
- Document intentional Flutter differences and release the parity behavior behind stable APIs.

## Acceptance criteria
- A ball moves at approximately constant pixels per second on the full spiral, including near the center.
- Curved JS path nodes with `ctrlX/ctrlY/ctrlZ` produce the same sampled positions in Flutter within a documented tolerance.
- The example continuously respawns balls after earlier balls finish; it never settles at one ball because of reflow.
