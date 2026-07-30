import '../runtime/track.dart';

/// Collects dirty graph nodes and publishes composed patches once per flush.
///
/// The publisher composes every node in the compiled order so parents share one
/// composition context with their children, but it only returns the nodes that
/// were actually marked dirty.
class MotionPathGraphPublisher {
  /// Creates a publisher over mounted [tracks].
  MotionPathGraphPublisher(this.tracks);

  /// Mounted tracks keyed by id.
  final Map<String, MotionPathTrackRuntime> tracks;

  final Set<String> _dirty = <String>{};

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

  /// Composes [order] parents-first and returns only the dirty patches.
  Map<String, Map<String, Object?>> flush(List<String> order) {
    if (_dirty.isEmpty) {
      return const <String, Map<String, Object?>>{};
    }
    final Set<String> dirty = Set<String>.of(_dirty);
    _dirty.clear();
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
        published[id] = patch;
      }
    }
    return published;
  }
}
