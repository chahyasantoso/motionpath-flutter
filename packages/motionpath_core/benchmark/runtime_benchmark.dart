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

void main() {
  final List<int> sizes = <int>[14, 50, 250];
  for (final int size in sizes) {
    final MotionPathMotionRuntime motion = buildMotion(size);
    final Stopwatch watch = Stopwatch()..start();
    for (int sample = 0; sample < 100; sample++) {
      motion.seek(sample / 99);
      motion.composeGraph();
    }
    watch.stop();
    stdout.writeln('$size tracks: ${watch.elapsedMicroseconds} us / 100 samples');
  }
}
