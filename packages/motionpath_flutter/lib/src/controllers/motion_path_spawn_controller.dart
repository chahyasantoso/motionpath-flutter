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

  /// Settled or currently tweened offset inside the parent, in seconds.
  final double offset;

  /// Normalized child playhead.
  final double progress;

  /// Whether the parent's elapsed time has reached this child.
  final bool hasStarted;

  /// Composed, renderer-neutral patch for this child.
  final Map<String, Object?> patch;

  @override
  String toString() => 'MotionPathSpawnInstance($id, offset: $offset, progress: $progress)';
}

/// Mounts a track's children at their settled offsets and drains them.
class MotionPathSpawnController extends ChangeNotifier {
  /// Wires this controller into [parent]'s composition hooks.
  MotionPathSpawnController({
    required this.parent,
    this.childDuration = 1,
    this.drainOnComplete = false,
    this.reflowDuration = 0,
    this.reflowEase = MotionPathInterpolators.linear,
  }) {
    if (parent.onChildSpawned != null || parent.onChildRemoved != null || parent.onChildReflowed != null) {
      throw StateError('Track "${parent.id}" already has composition hooks wired.');
    }
    parent.onChildSpawned = _handleSpawned;
    parent.onChildRemoved = _handleRemoved;
    parent.onChildReflowed = _handleReflowed;
    _rebuild();
  }

  /// Track whose children this controller mounts.
  final MotionPathTrackRuntime parent;

  /// Span used for a child without its own duration, in seconds.
  final double childDuration;

  /// Whether a child is removed once its playhead reaches the end.
  final bool drainOnComplete;

  /// Fixed reflow tween duration. Zero preserves immediate reflow.
  final double reflowDuration;

  /// Easing curve used by reflow tweens.
  final Easing reflowEase;

  double _elapsed = 0;
  bool _disposed = false;
  List<MotionPathSpawnInstance> _instances = const <MotionPathSpawnInstance>[];
  final Map<MotionPathTrackRuntime, MotionPathValueTweener> _reflows = <MotionPathTrackRuntime, MotionPathValueTweener>{};

  /// Elapsed time this controller last settled against.
  double get elapsed => _elapsed;

  /// Live children, ordered by effective offset.
  List<MotionPathSpawnInstance> get instances => _instances;

  /// Number of live children.
  int get liveCount => _instances.length;

  /// Whether this controller has been disposed.
  bool get isDisposed => _disposed;

  /// Places [child] through the parent's layout policy and mounts it.
  void spawn(MotionPathTrackRuntime child, {double stagger = 0}) {
    if (_disposed) return;
    parent.addChild(child, stagger: stagger);
    _settle();
  }

  /// Removes the child with [childId], applying the resulting reflow plan.
  void remove(String childId) {
    if (_disposed) return;
    parent.removeChild(childId);
    _settle();
  }

  /// Restarts the parent clock at zero after a wave has fully drained.
  void restartEmptyWave() {
    if (_disposed || parent.childCount != 0) return;
    _elapsed = 0;
    _reflows.clear();
    _settle();
  }

  /// Advances to an absolute elapsed time and republishes.
  void advanceTo(double elapsedSeconds) {
    if (_disposed) return;
    final double next = elapsedSeconds < 0 ? 0 : elapsedSeconds;
    final double delta = next - _elapsed;
    _elapsed = next;
    if (delta > 0) {
      for (final MotionPathValueTweener tweener in _reflows.values) tweener.advance(delta);
      _reflows.removeWhere((_, MotionPathValueTweener tweener) => tweener.isComplete);
    }
    _settle(drain: drainOnComplete);
  }

  /// Advances by [delta] seconds and republishes.
  void advanceBy(double delta) => advanceTo(_elapsed + delta);

  void _handleSpawned(MotionPathTrackRuntime child, double offset) {
    _reflows.remove(child);
    child.seek(_localProgress(child));
  }

  void _handleRemoved(MotionPathTrackRuntime child) {
    _reflows.remove(child);
    child.seek(0);
  }

  void _handleReflowed(MotionPathTrackRuntime child, double offset) {
    if (reflowDuration <= 0) {
      _reflows.remove(child);
      child.seek(_localProgress(child));
      return;
    }
    _reflows[child] = MotionPathValueTweener(
      initial: _publishedOffset(child),
      target: offset,
      duration: reflowDuration,
      ease: reflowEase,
    );
    child.seek(_localProgress(child));
  }

  void _settle({bool drain = false}) {
    _seekChildren();
    if (drain) _drain();
    _rebuild();
    notifyListeners();
  }

  void _seekChildren() {
    for (final MotionPathTrackRuntime child in parent.children) child.seek(_localProgress(child));
  }

  void _drain() {
    final List<String> completed = <String>[
      for (final MotionPathTrackRuntime child in parent.children) if (_localProgress(child) >= 1) child.id,
    ];
    if (completed.isEmpty) return;
    for (final String childId in completed) parent.removeChild(childId);
    _seekChildren();
  }

  void _rebuild() {
    final List<MotionPathTrackRuntime> ordered = <MotionPathTrackRuntime>[];
    for (final MotionPathTrackRuntime child in parent.children) {
      int slot = ordered.length;
      while (slot > 0 && _effectiveOffset(ordered[slot - 1]) > _effectiveOffset(child)) slot--;
      ordered.insert(slot, child);
    }
    _instances = List<MotionPathSpawnInstance>.unmodifiable(<MotionPathSpawnInstance>[
      for (final MotionPathTrackRuntime child in ordered)
        MotionPathSpawnInstance(
          id: child.id,
          offset: _effectiveOffset(child),
          progress: child.progress,
          hasStarted: _elapsed >= _effectiveOffset(child),
          patch: child.compose(),
        ),
    ]);
  }

  double _spanOf(MotionPathTrackRuntime child) => child.duration > 0 ? child.duration : (childDuration > 0 ? childDuration : 1);

  double _publishedOffset(MotionPathTrackRuntime child) {
    for (final MotionPathSpawnInstance instance in _instances) {
      if (instance.id == child.id) return instance.offset;
    }
    return child.currentOffset;
  }

  double _effectiveOffset(MotionPathTrackRuntime child) => _reflows[child]?.value ?? child.currentOffset;

  double _localProgress(MotionPathTrackRuntime child) => ((_elapsed - _effectiveOffset(child)) / _spanOf(child)).clamp(0.0, 1.0).toDouble();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    parent.onChildSpawned = null;
    parent.onChildRemoved = null;
    parent.onChildReflowed = null;
    _reflows.clear();
    _instances = const <MotionPathSpawnInstance>[];
    super.dispose();
  }
}
