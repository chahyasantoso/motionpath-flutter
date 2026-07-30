import '../composition/patch_composition.dart';
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

  /// Called with renderer-facing patches after each composed tick.
  ///
  /// This is the only hook a renderer needs: the core never knows who listens.
  void Function(Map<String, Map<String, Object?>> patches)? onPatches;

  Map<String, Map<String, Object?>> _patches = const <String, Map<String, Object?>>{};

  /// The most recently composed renderer-facing patches, keyed by track id.
  Map<String, Map<String, Object?>> get patches => _patches;

  void prepare(ObservationGraph nextGraph) => graph = nextGraph;
  void play() => playing = true;
  void pause() => playing = false;
  void reverse() => seek(1 - progress);

  void seek(double value) {
    progress = value.clamp(0.0, 1.0).toDouble();
    for (final MotionPathTrackRuntime track in tracks) {
      track.seek(progress);
    }
  }

  /// Composes every track parent-first and returns the renderer-facing patches.
  ///
  /// Input edges deliver the observed patch under the authored key, output edges
  /// merge the observed patch on top, and bone data is folded into flat world
  /// coordinates before internal keys are stripped.
  Map<String, Map<String, Object?>> composeGraph() {
    final ObservationGraph? currentGraph = graph;
    if (currentGraph == null) return const <String, Map<String, Object?>>{};
    final Map<String, MotionPathTrackRuntime> byId = <String, MotionPathTrackRuntime>{
      for (final MotionPathTrackRuntime track in tracks) track.id: track,
    };
    final Map<String, Map<String, Object?>> composed = <String, Map<String, Object?>>{};
    for (final String id in currentGraph.order) {
      final MotionPathTrackRuntime? track = byId[id];
      if (track == null) continue;
      final Map<String, Object?> inputs = <String, Object?>{};
      for (final ObservationEdge edge in currentGraph.edges) {
        if (edge.target != id || edge.role != 'input') continue;
        final Map<String, Object?>? source = composed[edge.source];
        if (source == null) continue;
        inputs[edge.inputKey ?? edge.source] = Map<String, Object?>.of(source);
      }
      Map<String, Object?> patch = track.compose(inputs: inputs);
      for (final ObservationEdge edge in currentGraph.edges) {
        if (edge.target != id || edge.role != 'output') continue;
        final Map<String, Object?>? source = composed[edge.source];
        if (source != null) patch.addAll(source);
      }
      patch = applyForwardKinematics(patch);
      composed[id] = patch;
    }
    final Map<String, Map<String, Object?>> published = <String, Map<String, Object?>>{};
    for (final MapEntry<String, Map<String, Object?>> entry in composed.entries) {
      published[entry.key] = stripInternalPatchKeys(entry.value);
    }
    _patches = published;
    return published;
  }

  void tick(double delta) {
    seek(progress + delta / duration);
    final Map<String, Map<String, Object?>> published = composeGraph();
    final void Function(Map<String, Map<String, Object?>>)? listener = onPatches;
    if (listener != null) listener(published);
    if (progress >= 1) pause();
  }

  void dispose() {
    onPatches = null;
    for (final MotionPathTrackRuntime track in tracks) {
      track.dispose();
    }
    tracks.clear();
    _patches = const <String, Map<String, Object?>>{};
  }
}
