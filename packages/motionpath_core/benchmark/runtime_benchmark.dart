import 'dart:convert';
import 'dart:io';

import 'package:motionpath_core/motionpath_core.dart';

MotionPathMotionRuntime buildMotion(int count) {
  final List<MotionPathTrackRuntime> tracks = <MotionPathTrackRuntime>[];
  for (int index = 0; index < count; index++) {
    tracks.add(MotionPathTrackRuntime(
      'track-$index',
      properties: <String, List<MotionPathStop>>{
        'x': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 100),
        ],
        'opacity': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 1, value: 1),
        ],
      },
    ));
  }
  final MotionPathMotionRuntime motion = MotionPathMotionRuntime(
    id: 'benchmark',
    tracks: tracks,
  );
  motion.prepare(ObservationGraph(
    nodes: <ObservationNode>[
      for (int index = 0; index < count; index++)
        ObservationNode('track-$index', index: index),
    ],
    edges: const <ObservationEdge>[],
    order: <String>[for (int index = 0; index < count; index++) 'track-$index'],
    errors: const <MotionPathDiagnostic>[],
  ));
  return motion;
}

class BenchmarkResult {
  BenchmarkResult({
    required this.tracks,
    required this.warmupSamples,
    required this.samples,
    required this.runs,
  });

  final int tracks;
  final int warmupSamples;
  final int samples;
  final List<int> runs;

  int get minimum => runs.reduce((int a, int b) => a < b ? a : b);
  int get maximum => runs.reduce((int a, int b) => a > b ? a : b);
  double get mean => runs.reduce((int a, int b) => a + b) / runs.length;

  Map<String, Object> toJson() => <String, Object>{
        'tracks': tracks,
        'warmupSamples': warmupSamples,
        'samples': samples,
        'runsMicroseconds': runs,
        'minMicroseconds': minimum,
        'meanMicroseconds': mean,
        'maxMicroseconds': maximum,
      };
}

BenchmarkResult runBenchmark({
  required int tracks,
  int warmupSamples = 20,
  int samples = 100,
  int runs = 5,
}) {
  if (warmupSamples < 0 || samples <= 0 || runs <= 0) {
    throw ArgumentError('warmupSamples must be >= 0; samples and runs must be > 0.');
  }
  final MotionPathMotionRuntime motion = buildMotion(tracks);
  for (int sample = 0; sample < warmupSamples; sample++) {
    motion.seek(sample / (warmupSamples == 1 ? 1 : warmupSamples - 1));
    motion.composeGraph();
  }

  final List<int> measurements = <int>[];
  for (int run = 0; run < runs; run++) {
    final Stopwatch watch = Stopwatch()..start();
    for (int sample = 0; sample < samples; sample++) {
      motion.seek(sample / (samples == 1 ? 1 : samples - 1));
      motion.composeGraph();
    }
    watch.stop();
    measurements.add(watch.elapsedMicroseconds);
  }
  return BenchmarkResult(
    tracks: tracks,
    warmupSamples: warmupSamples,
    samples: samples,
    runs: measurements,
  );
}

void main(List<String> args) {
  final bool json = args.contains('--json');
  final List<int> sizes = <int>[14, 50, 250];
  final List<BenchmarkResult> results = <BenchmarkResult>[
    for (final int size in sizes) runBenchmark(tracks: size),
  ];
  if (json) {
    stdout.writeln(jsonEncode(<String, Object>{
      'dartVersion': Platform.version,
      'results': <Map<String, Object>>[
        for (final BenchmarkResult result in results) result.toJson(),
      ],
    }));
    return;
  }
  stdout.writeln('MotionPath runtime benchmark');
  stdout.writeln('warmup: 20 samples, measured: 100 samples x 5 runs');
  stdout.writeln('dart: ${Platform.version.split(' ').first}');
  for (final BenchmarkResult result in results) {
    stdout.writeln(
      '${result.tracks} tracks: min ${result.minimum} us, '
      'mean ${result.mean.toStringAsFixed(1)} us, max ${result.maximum} us',
    );
  }
}
