import 'package:flutter/foundation.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// One live child of a spawning track, ready for a painter or a widget list.
@immutable
class MotionPathSpawnInstance {
  /// Creates an instance record.
  const MotionPathSpawnInstance({
    required this.id,
    required this.offset,
    required this.progress,
    required this.hasStarted,
    required this.patch,
  });

  /// Child track id.
  final String id;

  /// Settled offset inside the parent, in seconds.
  final double offset;

  /// Normalized playhead of this child, in `[0, 1]`.
  final double progress;

  /// Whether the parent's elapsed time has reached this child's offset.
  ///
  /// A child that has not started reads a [progress] of zero, which is
  /// indistinguishable from one sitting on its first stop. A renderer that
  /// should not paint an unspawned item needs this flag, not the playhead.
  final bool hasStarted;

  /// Composed, renderer-neutral patch for this child.
  final Map<String, Object?> patch;

  @override
  String toString() =>
      'MotionPathSpawnInstance($id, offset: $offset, progress: $progress)';
}

/// Mounts a track's children at their settled offsets and drains them.
///
/// The pure Dart core decides *where* a child belongs: it places one through
/// its layout policy and reports the settled offset. It deliberately does not
/// schedule anything, so until something mounts that child its playhead never
/// moves. This is that something.
///
/// It is not a frame source. It converts an elapsed time it is handed into
/// per-child playheads, so a ticker, a scroll driver, or a test can drive it
/// without any of them competing.
///
/// One controller owns one parent track, because the parent exposes a single
/// slot per composition hook. Constructing a second controller for the same
/// parent throws rather than silently stealing the first one's hooks.
class MotionPathSpawnController extends ChangeNotifier {
  /// Wires this controller into [parent]'s composition hooks.
  MotionPathSpawnController({
    required this.parent,
    this.childDuration = 1,
    this.drainOnComplete = false,
  }) {
    if (parent.onChildSpawned != null ||
        parent.onChildRemoved != null ||
        parent.onChildReflowed != null) {
      throw StateError(
        'Track "${parent.id}" already has composition hooks wired.',
      );
    }
    parent.onChildSpawned = _handleSpawned;
    parent.onChildRemoved = _handleRemoved;
    parent.onChildReflowed = _handleReflowed;
    _rebuild();
  }

  /// Track whose children this controller mounts.
  final MotionPathTrackRuntime parent;

  /// Span used for a child that authored no duration of its own, in seconds.
  final double childDuration;

  /// Whether a child is removed once its playhead reaches the end.
  final bool drainOnComplete;

  double _elapsed = 0;
  bool _disposed = false;
  List<MotionPathSpawnInstance> _instances = const <MotionPathSpawnInstance>[];

  /// Elapsed time this controller last settled against, in seconds.
  double get elapsed => _elapsed;

  /// Live children, ordered by settled offset.
  ///
  /// Offset order, not insertion order: a manually staggered child can land
  /// anywhere relative to its auto-placed siblings, and this is the same order
  /// the layout policy reflows in.
  List<MotionPathSpawnInstance> get instances => _instances;

  /// Number of live children.
  int get liveCount => _instances.length;

  /// Whether this controller has been disposed.
  bool get isDisposed => _disposed;

  /// Places [child] through the parent's layout policy and mounts it.
  void spawn(MotionPathTrackRuntime child, {double stagger = 0}) {
    if (_disposed) {
      return;
    }
    parent.addChild(child, stagger: stagger);
    _settle();
  }

  /// Removes the child with [childId], applying any reflow the policy plans.
  void remove(String childId) {
    if (_disposed) {
      return;
    }
    parent.removeChild(childId);
    _settle();
  }

  /// Advances to an absolute [elapsedSeconds] and republishes.
  void advanceTo(double elapsedSeconds) {
    if (_disposed) {
      return;
    }
    _elapsed = elapsedSeconds < 0 ? 0 : elapsedSeconds;
    _settle(drain: drainOnComplete);
  }

  /// Advances by [delta] seconds and republishes.
  void advanceBy(double delta) => advanceTo(_elapsed + delta);

  void _handleSpawned(MotionPathTrackRuntime child, double offset) {
    // A freshly placed child must not inherit the previous frame's playhead.
    child.seek(_localProgress(child));
  }

  void _handleRemoved(MotionPathTrackRuntime child) {
    child.seek(0);
  }

  void _handleReflowed(MotionPathTrackRuntime child, double offset) {
    // The survivor slid into the removed child's slot, so its playhead has to
    // be recomputed from the new offset, not carried over from the old one.
    child.seek(_localProgress(child));
  }

  void _settle({bool drain = false}) {
    _seekChildren();
    if (drain) {
      _drain();
    }
    _rebuild();
    notifyListeners();
  }

  void _seekChildren() {
    for (final MotionPathTrackRuntime child in parent.children) {
      child.seek(_localProgress(child));
    }
  }

  /// Removes every child that finished, in exactly one pass.
  ///
  /// One pass, deliberately. A mid-chain removal reflows the survivors earlier,
  /// which can push one of them to completion; draining again in the same frame
  /// would cascade that into an avalanche of instant completions during what
  /// should be a natural drain. Anything that completes because of a reflow is
  /// collected on the next advance instead.
  void _drain() {
    final List<String> completed = <String>[
      for (final MotionPathTrackRuntime child in parent.children)
        if (_localProgress(child) >= 1) child.id,
    ];
    if (completed.isEmpty) {
      return;
    }
    for (final String childId in completed) {
      parent.removeChild(childId);
    }
    _seekChildren();
  }

  void _rebuild() {
    final List<MotionPathTrackRuntime> ordered = <MotionPathTrackRuntime>[];
    for (final MotionPathTrackRuntime child in parent.children) {
      int slot = ordered.length;
      while (slot > 0 &&
          ordered[slot - 1].currentOffset > child.currentOffset) {
        slot--;
      }
      ordered.insert(slot, child);
    }
    _instances = List<MotionPathSpawnInstance>.unmodifiable(
      <MotionPathSpawnInstance>[
        for (final MotionPathTrackRuntime child in ordered)
          MotionPathSpawnInstance(
            id: child.id,
            offset: child.currentOffset,
            progress: child.progress,
            hasStarted: _elapsed >= child.currentOffset,
            patch: child.compose(),
          ),
      ],
    );
  }

  double _spanOf(MotionPathTrackRuntime child) {
    if (child.duration > 0) {
      return child.duration;
    }
    return childDuration > 0 ? childDuration : 1;
  }

  double _localProgress(MotionPathTrackRuntime child) =>
      ((_elapsed - child.currentOffset) / _spanOf(child))
          .clamp(0.0, 1.0)
          .toDouble();

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    parent.onChildSpawned = null;
    parent.onChildRemoved = null;
    parent.onChildReflowed = null;
    _instances = const <MotionPathSpawnInstance>[];
    super.dispose();
  }
}
