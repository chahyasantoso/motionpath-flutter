# Runtime benchmarks

The benchmark measures pure Dart graph composition only. It does not measure Flutter rasterization, image decoding, widget layout, or device frame pacing.

## Run

From `packages/motionpath_core`:

```sh
dart run benchmark/runtime_benchmark.dart
dart run benchmark/runtime_benchmark.dart --json
```

The harness reports 14, 50, and 250-track compositions. Each size gets a 20-sample warmup followed by five measured runs of 100 seek-plus-compose samples. Human-readable output reports minimum, mean, and maximum elapsed microseconds. `--json` emits the Dart version and machine-readable measurements for recording in CI artifacts or a local commit note.

## Interpretation

Compare runs only on the same machine, Dart SDK, build mode, and repository commit. The harness is intentionally not a CI gate: shared runners are noisy and these numbers are not cross-machine performance claims. Use the minimum to spot a best-case floor, the mean for the normal signal, and the maximum to catch obvious scheduling noise.

When recording results, include the commit SHA, OS, CPU, Dart version, and the complete JSON output. Never turn a single local run into a package-wide performance promise.
