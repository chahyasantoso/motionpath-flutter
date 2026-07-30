import '../graph/observation_graph.dart';
import '../runtime/track.dart';
import 'patch_composition.dart';

/// Collects dirty tracks and publishes composed patches once per flush.
///
/// Composition always walks the full [ObservationGraph] order so a child sees a
/// freshly composed parent, but only dirty tracks are returned. That mirrors the
/// JavaScript `GraphPublisher`, which composes everything and publishes little.
class MotionPathGraphPublisher {
  MotionPathGraphPublisher(this.tracks, {this.graph});

  final Map<String, MotionPathTrackRuntime> tracks;

  /// Optional graph used to feed observed inputs while composing.
  final ObservationGraph? graph;

  final Set<String> _dirty = <String>{};

  /// Tracks queued for the next flush.
  Set<String> get dirty => Set<String>.unmodifiable(_dirty);

  void markDirty(String id) => _dirty.add(id);

  /// Queues every track in [order] that this publisher owns.
  void markAllDirty(Iterable<String> order) {
    for (final String id in order) {
      if (tracks.containsKey(id)) _dirty.add(id);
    }
  }

  Map<String, Map<String, Object?>> flush(List<String> order) {
    final Map<String, Map<String, Object?>> published = <String, Map<String, Object?>>{};
    final Map<String, Map<String, Object?>> composed = <String, Map<String, Object?>>{};
    for (final String id in order) {
      final MotionPathTrackRuntime? track = tracks[id];
      if (track == null) continue;
      final Map<String, Object?> patch = applyForwardKinematics(
        track.compose(inputs: _inputsFor(id, composed)),
      );
      composed[id] = patch;
      if (_dirty.contains(id)) published[id] = stripInternalPatchKeys(patch);
    }
    _dirty.clear();
    return published;
  }

  Map<String, Object?> _inputsFor(String id, Map<String, Map<String, Object?>> composed) {
    final ObservationGraph? currentGraph = graph;
    if (currentGraph == null) return const <String, Object?>{};
    final Map<String, Object?> inputs = <String, Object?>{};
    for (final ObservationEdge edge in currentGraph.edges) {
      if (edge.target != id || edge.role != 'input') continue;
      final Map<String, Object?>? source = composed[edge.source];
      if (source == null) continue;
      inputs[edge.inputKey ?? edge.source] = Map<String, Object?>.of(source);
    }
    return inputs;
  }
}
