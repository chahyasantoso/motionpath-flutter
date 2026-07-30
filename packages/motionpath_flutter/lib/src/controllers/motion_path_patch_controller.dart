import 'package:flutter/foundation.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Publishes composed patches to Flutter listeners.
class MotionPathPatchController extends ChangeNotifier {
  /// Creates a controller for [motion].
  MotionPathPatchController({required this.motion}) {
    _patches = motion.composeGraph();
  }

  /// Motion whose graph is published.
  final MotionPathMotionRuntime motion;

  Map<String, Map<String, Object?>> _patches =
      const <String, Map<String, Object?>>{};
  bool _disposed = false;

  /// Latest composed patches, keyed by track id.
  Map<String, Map<String, Object?>> get patches => _patches;

  /// Latest patch for one track, or an empty patch when it is unknown.
  Map<String, Object?> patchFor(String trackId) =>
      _patches[trackId] ?? const <String, Object?>{};

  /// Advances the motion by [delta] seconds and republishes.
  void tick(double delta) {
    if (_disposed) {
      return;
    }
    motion.tick(delta);
    publish();
  }

  /// Moves the playhead to [progress] and republishes.
  void seek(double progress) {
    if (_disposed) {
      return;
    }
    motion.seek(progress);
    publish();
  }

  /// Recomposes the graph and notifies listeners.
  void publish() {
    if (_disposed) {
      return;
    }
    _patches = motion.composeGraph();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    super.dispose();
  }
}
