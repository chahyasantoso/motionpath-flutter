import '../graph/observation_graph.dart';
import 'track.dart';

class MotionPathMotionRuntime {
  MotionPathMotionRuntime({required this.id, required this.tracks});
  final String id;
  final List<MotionPathTrackRuntime> tracks;
  double progress = 0;
  bool playing = false;
  ObservationGraph? graph;
  double duration = 1;

  void prepare(ObservationGraph nextGraph) => graph = nextGraph;
  void play() => playing = true;
  void pause() => playing = false;
  void reverse() => seek(1 - progress);
  void seek(double value) {
    progress = value.clamp(0.0, 1.0).toDouble();
    for (final track in tracks) track.seek(progress);
  }

  Map<String, Map<String, Object?>> composeGraph() {
    final compiled = graph?.order ?? const <String>[];
    final currentGraph = graph;
    if (currentGraph == null) return const <String, Map<String, Object?>>{};
    final byId = <String, MotionPathTrackRuntime>{for (final track in tracks) track.id: track};
    final patches = <String, Map<String, Object?>>{};
    for (final id in compiled) {
      final track = byId[id];
      if (track == null) continue;
      final inputs = <String, Object?>{};
      for (final edge in currentGraph.edges) {
        if (edge.target != id || edge.role != 'input') continue;
        final source = patches[edge.source];
        if (source != null) inputs[edge.target] = source;
      }
      final patch = track.compose(inputs: inputs);
      for (final edge in currentGraph.edges) {
        if (edge.target != id || edge.role != 'output') continue;
        final source = patches[edge.source];
        if (source != null) patch.addAll(source);
      }
      patches[id] = patch;
    }
    return patches;
  }

  void tick(double delta) {
    seek(progress + delta / duration);
    composeGraph();
    if (progress >= 1) pause();
  }

  void dispose() {
    for (final track in tracks) track.dispose();
    tracks.clear();
  }
}
