import 'package:flutter/foundation.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Publishes composed patches to Flutter listeners.
///
/// The controller is the only place patches cross from the pure Dart core into
/// Flutter. Painters listen to it, so a frame never rebuilds a widget subtree
/// just to move a pixel.
class MotionPathPatchController extends ChangeNotifier {
  /// Creates a controller for [motion].
  MotionPathPatchController({required this.motion}) {
    _patches = motion.composeGraph();
  }

  /// Motion whose graph is published.
  final MotionPathMotionRuntime motion;

  Map<String, Map<String, Object?>> _patches =
      const <String, Map<String, Object?>>{};

  /// Latest composed patches, keyed by track id.
  Map<String, Map<String, Object?>> get patches => _patches;

  /// Latest patch for one track, or an empty patch when it is unknown.
  Map<String, Object?> patchFor(String trackId) =>
      _patches[trackId] ?? const <String, Object?>{};

  /// Advances the motion by [delta] seconds and republishes.
  void tick(double delta) {
    motion.tick(delta);
    publish();
  }

  /// Moves the playhead to [progress] and republishes.
  void seek(double progress) {
    motion.seek(progress);
    publish();
  }

  /// Recomposes the graph and notifies listeners.
  void publish() {
    _patches = motion.composeGraph();
    notifyListeners();
  }
}
