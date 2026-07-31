import 'package:flutter/foundation.dart';
import 'package:motionpath_core/motionpath_core.dart';

import '../consumers/motion_path_patch_equality.dart';

/// A per-track patch notifier that can report whether anything watches it.
///
/// `ChangeNotifier.hasListeners` is protected, so the controller needs its own
/// subclass to answer "is this track actually interesting to someone?".
class _TrackPatchNotifier extends ValueNotifier<Map<String, Object?>> {
  _TrackPatchNotifier(super.value);

  bool get isWatched => hasListeners;
}

/// Publishes composed patches to Flutter listeners.
///
/// Two consumer shapes are supported and they compose differently:
///
/// * Whole-graph consumers listen to the controller itself and always receive
///   the complete patch map. Walker-style scenes depend on this, so the
///   presence of a single whole-graph listener forces full composition.
/// * Interest-scoped consumers listen to [trackPatch]. When they are the only
///   listeners, the controller composes just the watched ids. Core still
///   resolves each watched track's observed dependencies, so filtering is a
///   scope reduction and never a correctness change.
class MotionPathPatchController extends ChangeNotifier {
  /// Creates a controller for [motion].
  MotionPathPatchController({required this.motion}) {
    _patches = motion.composeGraph();
    _lastComposedIds = _patches.keys.toSet();
  }

  /// Motion whose graph is published.
  final MotionPathMotionRuntime motion;

  final Map<String, _TrackPatchNotifier> _trackPatches =
      <String, _TrackPatchNotifier>{};

  Map<String, Map<String, Object?>> _patches =
      const <String, Map<String, Object?>>{};
  Set<String> _lastComposedIds = <String>{};
  bool _disposed = false;

  /// Latest composed patches, keyed by track id.
  ///
  /// After an interest-scoped composition only the watched ids are fresh; the
  /// rest keep their last composed values. Use a whole-graph listener when a
  /// consumer needs every track updated every frame.
  Map<String, Map<String, Object?>> get patches => _patches;

  /// Latest patch for one track, or an empty patch when it is unknown.
  Map<String, Object?> patchFor(String trackId) =>
      _patches[trackId] ?? const <String, Object?>{};

  /// Whether any consumer at all is listening, whole-graph or interest-scoped.
  bool get hasAnyListener => hasListeners || _watchedTrackIds.isNotEmpty;

  /// Number of live per-track notifiers, for leak assertions.
  @visibleForTesting
  int get debugTrackPatchCount => _trackPatches.length;

  Set<String> get _watchedTrackIds => <String>{
        for (final MapEntry<String, _TrackPatchNotifier> entry
            in _trackPatches.entries)
          if (entry.value.isWatched) entry.key,
      };

  /// A patch listenable scoped to one track, for `ValueListenableBuilder`.
  ///
  /// The notifier is created on demand and seeded with the last composed patch
  /// for [trackId], so a consumer that subscribes to a track which has not
  /// composed yet starts empty instead of throwing.
  ValueListenable<Map<String, Object?>> trackPatch(String trackId) {
    assert(!_disposed, 'trackPatch() called on a disposed controller.');
    return _trackPatches.putIfAbsent(
      trackId,
      () => _TrackPatchNotifier(patchFor(trackId)),
    );
  }

  /// Drops the notifier for [trackId].
  ///
  /// Call this when a host stops rendering a track it explicitly registered.
  /// The notifier is disposed, so no consumer may still be bound to it.
  void releaseTrackPatch(String trackId) {
    final _TrackPatchNotifier? notifier = _trackPatches.remove(trackId);
    notifier?.dispose();
  }

  /// Advances the motion by [delta] seconds and republishes.
  ///
  /// Frame-driven composition is gated when nothing is listening anywhere. The
  /// playhead still advances, so time never silently stalls and a consumer that
  /// attaches later sees the correct position rather than a rewound one. The
  /// gate is deliberately limited to [tick]: [seek] and [publish] are
  /// imperative calls and always compose.
  void tick(double delta) {
    if (_disposed) {
      return;
    }
    // Advance without composing. The controller owns composition scope from
    // here, which is also what keeps a tick from composing the graph twice.
    motion.advance(delta, publishPatches: false);
    if (!hasAnyListener) {
      return;
    }
    _composeAndNotify();
  }

  /// Moves the playhead to [progress] and republishes.
  void seek(double progress) {
    if (_disposed) {
      return;
    }
    motion.seek(progress);
    _composeAndNotify();
  }

  /// Recomposes and notifies listeners.
  void publish() {
    if (_disposed) {
      return;
    }
    _composeAndNotify();
  }

  void _composeAndNotify() {
    final Set<String> watched = _watchedTrackIds;
    if (hasListeners || watched.isEmpty) {
      // A whole-graph listener, or an imperative call with no listeners at all,
      // gets the unchanged full-map contract. `motion.publish()` composes once
      // and still fires the host's `onPatches` hook.
      _patches = motion.publish();
      _pruneVanishedTrackPatches();
      _notifyTrackPatches(_patches.keys);
      notifyListeners();
      return;
    }
    final Map<String, Map<String, Object?>> composed =
        motion.composeGraph(only: watched);
    _patches = <String, Map<String, Object?>>{..._patches, ...composed};
    _notifyTrackPatches(composed.keys);
  }

  void _notifyTrackPatches(Iterable<String> trackIds) {
    for (final String trackId in trackIds) {
      final _TrackPatchNotifier? notifier = _trackPatches[trackId];
      if (notifier == null) {
        continue;
      }
      final Map<String, Object?> next = patchFor(trackId);
      // Dirty checking has to be deep. Composed patches carry nested filter,
      // CSS, image, and instance payloads that a shallow compare would miss.
      if (motionPathPatchEquals(notifier.value, next)) {
        continue;
      }
      notifier.value = next;
    }
  }

  /// Disposes notifiers whose track disappeared from the composed graph.
  ///
  /// Only runs after a full composition, and only for ids that were present in
  /// the previous full pass. A notifier registered ahead of a track that has
  /// not composed yet must survive, otherwise dynamic hosts could never
  /// subscribe before the first frame.
  void _pruneVanishedTrackPatches() {
    final Set<String> live = _patches.keys.toSet();
    if (_trackPatches.isNotEmpty) {
      final List<String> vanished = <String>[
        for (final String trackId in _trackPatches.keys)
          if (!live.contains(trackId) && _lastComposedIds.contains(trackId))
            trackId,
      ];
      for (final String trackId in vanished) {
        final _TrackPatchNotifier notifier = _trackPatches.remove(trackId)!;
        notifier.value = const <String, Object?>{};
        notifier.dispose();
      }
    }
    _lastComposedIds = live;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final _TrackPatchNotifier notifier in _trackPatches.values) {
      notifier.dispose();
    }
    _trackPatches.clear();
    super.dispose();
  }
}
