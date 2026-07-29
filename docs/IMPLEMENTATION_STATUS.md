# Implementation status

## Completed

- Phase 0: package boundaries, documentation, CI, analyzer configuration, and smoke tests.
- Phase 1: v4 project/motion/track contract, JSON parsing, structured diagnostics, and collect-all validation.
- Phase 2: immutable observation graph nodes and edges, stable topological ordering, diagnostics, and dependency policy.
- Phase 3: numeric interpolation, normalized Track progress, Motion playback controls, Engine lifecycle, mount-time graph compilation, and runtime tests.
- Phase 4 slice: delay/repeat/yoyo trigger math, dirty-track GraphPublisher, and a single-source Flutter Ticker driver boundary.

## Next

Add Engine tick propagation, authored keyframe-to-stop compilation, input/output graph patch composition, and CustomPainter rendering. Keep the ticker as the only frame source.

## Honest status

The ticker driver is wired as an ownership boundary but does not yet advance Engine state. The publisher batches patches but does not yet merge observation inputs/outputs. Those are deliberate next slices, not hidden capabilities.
