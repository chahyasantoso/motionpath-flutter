import '../composition/patch_composition.dart';
import '../graph/observation_graph.dart';
import '../runtime/track.dart';

/// Collects dirty graph nodes and publishes composed patches once per flush.
class MotionPathGraphPublisher {
  /// Creates a publisher over mounted [tracks] and an optional compiled graph.
  MotionPathGraphPublisher(this.tracks, {this.graph}) {
    _wireGraph();
  }

  /// Mounted tracks keyed by id.
  final Map<String, MotionPathTrackRuntime> tracks;

  /// Graph whose observation edges provide parent inputs during composition.
  final ObservationGraph? graph;

  final Set<String> _dirty = <String>{};

  void _wireGraph() {
    final ObservationGraph? current = graph;
    if (current == null) {
      return;
    }
    for (final ObservationEdge edge in current.edges) {
      final MotionPathTrackRuntime? source = tracks[edge.source];
      final MotionPathTrackRuntime? target = tracks[edge.target];
      if (source == null || target == null) {
        continue;
      }
      target.observe(source, role: edge.role, input: edge.input);
    }
  }

  /// Whether anything is pending publication.
  bool get isDirty => _dirty.isNotEmpty;

  /// Marks one track dirty.
  void markDirty(String id) {
    if (tracks.containsKey(id)) {
      _dirty.add(id);
    }
  }

  /// Marks every track in [order] dirty.
  void markAllDirty(Iterable<String> order) {
    for (final String id in order) {
      markDirty(id);
    }
  }

  /// Composes every node in [order] parent-first, but publishes only dirty nodes.
  ///
  /// The shared composition context keeps parent patches available to child
  /// observations while avoiding duplicate work for diamond-shaped graphs.
  Map<String, Map<String, Object?>> flush(List<String> order) {
    if (_dirty.isEmpty) {
      return const <String, Map<String, Object?>>{};
    }
    final Set<String> dirty = Set<String>.of(_dirty);
    final Map<MotionPathTrackRuntime, Map<String, Object?>?> context =
        <MotionPathTrackRuntime, Map<String, Object?>?>{};
    final Map<String, Map<String, Object?>> published =
        <String, Map<String, Object?>>{};
    for (final String id in order) {
      final MotionPathTrackRuntime? track = tracks[id];
      if (track == null) {
        continue;
      }
      final Map<String, Object?> patch = track.compose(context: context);
      if (dirty.contains(id)) {
        published[id] = stripInternalPatchKeys(patch);
      }
    }
    _dirty.clear();
    return published;
  }
}
