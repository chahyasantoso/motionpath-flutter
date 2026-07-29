import '../graph/observation_graph.dart';
import 'track.dart';

class MotionPathMotionRuntime {
  MotionPathMotionRuntime({required this.id, required this.tracks});
  final String id;
  final List<MotionPathTrackRuntime> tracks;
  double progress = 0;
  bool playing = false;

  ObservationGraph? graph;

  void prepare(ObservationGraph nextGraph) => graph = nextGraph;

  void play() => playing = true;
  void pause() => playing = false;
  void reverse() => seek(1 - progress);
  void seek(double value) {
    progress = value.clamp(0.0, 1.0);
    for (final track in tracks) track.seek(progress);
  }

  void dispose() {
    for (final track in tracks) track.dispose();
    tracks.clear();
  }
}
