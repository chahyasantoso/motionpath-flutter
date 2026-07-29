import '../runtime/track.dart';

class MotionPathGraphPublisher {
  MotionPathGraphPublisher(this.tracks);
  final Map<String, MotionPathTrackRuntime> tracks;
  final Set<String> _dirty = <String>{};

  void markDirty(String id) => _dirty.add(id);

  Map<String, Map<String, Object?>> flush(List<String> order) {
    final published = <String, Map<String, Object?>>{};
    for (final id in order) {
      if (!_dirty.contains(id)) continue;
      final track = tracks[id];
      if (track == null) continue;
      published[id] = track.compose();
    }
    _dirty.clear();
    return published;
  }
}
