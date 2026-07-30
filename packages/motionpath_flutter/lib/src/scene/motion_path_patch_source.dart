import 'package:flutter/foundation.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Holds the latest composed patches and notifies painters when they change.
///
/// This is the whole renderer boundary: the pure Dart core publishes plain maps
/// through [MotionPathMotionRuntime.onPatches], and Flutter turns that into
/// repaint signals. The core stays free of any Flutter import.
class MotionPathPatchSource extends ChangeNotifier {
  Map<String, Map<String, Object?>> _patches = const <String, Map<String, Object?>>{};

  /// The latest composed patches, keyed by track id.
  Map<String, Map<String, Object?>> get patches => _patches;

  /// The latest patch for [trackId], or an empty patch when it has not composed.
  Map<String, Object?> patchFor(String trackId) => _patches[trackId] ?? const <String, Object?>{};

  /// Replaces the published patches and invalidates every listener.
  void publish(Map<String, Map<String, Object?>> next) {
    _patches = Map<String, Map<String, Object?>>.unmodifiable(next);
    notifyListeners();
  }

  /// Routes [motion]'s composed ticks into this source.
  void bind(MotionPathMotionRuntime motion) => motion.onPatches = publish;
}
