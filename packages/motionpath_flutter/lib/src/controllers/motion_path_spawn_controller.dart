import 'package:flutter/foundation.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// One live child of a spawning track, ready for a painter or a widget list.
@immutable
class MotionPathSpawnInstance {
  const MotionPathSpawnInstance({
    required this.id,
    required this.offset,
    required this.progress,
    required this.hasStarted,
    required this.patch,
  });

  final String id;
  final double offset;
  final double progress;
  final bool hasStarted;
  final Map<String, Object?> patch;

  @override
  String toString() =>
      'MotionPathSpawnInstance($id, offset: $offset, progress: $progress)';
}

/// Mounts a track's children at their settled offsets and drains them.
class MotionPathSpawnController extends ChangeNotifier {
  MotionPathSpawnController({
    required this.parent,
    this.childDuration = 1,
    this.drainOnComplete = false,
    this.reflowDuration = 0,
    this.reflowEase = MotionPathInterpolators.linear,
  }) {
    if (parent.onChildSpawned != null ||
        parent.onChildRemoved != null ||
        parent.onChildReflowed != null) {
      throw StateError(
        'Track "${parent.id}" already has composition hooks wired.',
      );
    }
    if (!reflowDuration.isFinite || reflowDuration < 0) {
      throw ArgumentError.value(
        reflowDuration,
        'reflowDuration',
        'must be finite and non-negative',
      );
    }
    parent.onChildSpawned = _handleSpawned;
    parent.onChildRemoved = _handleRemoved;
    parent.onChildReflowed = _handleReflowed;
    _rebuild();
  }

  final MotionPathTrackRuntime parent;
  final double childDuration;
  final bool drainOnComplete;
  final double reflowDuration;
  final Easing reflowEase;

  double _elapsed = 0;
  bool _disposed = false;
  List<MotionPathSpawnInstance> _instances = const <MotionPathSpawnInstance>[];
  final Map<MotionPathTrackRuntime, MotionPathValueTweener> _reflows =
      <MotionPathTrackRuntime, MotionPathValueTweener>{};

  double get elapsed => _elapsed;
  List<MotionPathSpawnInstance> get instances => _instances;
  int get liveCount => _instances.length;
  bool get isDisposed => _disposed;

  void spawn(MotionPathTrackRuntime child, {double stagger = 0}) {
    if (_disposed) return;
    parent.addChild(child, stagger: stagger);
    _settle();
  }

  void remove(String childId) {
    if (_disposed) return;
    parent.removeChild(childId);
    _settle();
  }

  void restartEmptyWave() {
    if (_disposed || parent.childCount != 0) return;
    _elapsed = 0;
    _reflows.clear();
    _settle();
  }

  void advanceTo(double elapsedSeconds) {
    if (_disposed) return;
    final double nextElapsed = elapsedSeconds < 0 ? 0 : elapsedSeconds;
    final double delta = nextElapsed - _elapsed;
    _elapsed = nextElapsed;
    _advanceReflows(delta);
    _settle(drain: drainOnComplete);
  }

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
    final double current = _reflows[child]?.value ?? child.currentOffset;
    if (reflowDuration <= 0 || current == offset) {
      _reflows.remove(child);
    } else {
      _reflows[child] = MotionPathValueTweener(
        initial: current,
        target: offset,
        duration: reflowDuration,
        ease: reflowEase,
      );
    }
    child.seek(_localProgress(child));
  }

  void _advanceReflows(double delta) {
    if (delta <= 0 || _reflows.isEmpty) return;
    final List<MotionPathTrackRuntime> complete = <MotionPathTrackRuntime>[];
    for (final MapEntry<MotionPathTrackRuntime, MotionPathValueTweener> entry
        in _reflows.entries) {
      entry.value.advance(delta);
      if (entry.value.isComplete) complete.add(entry.key);
    }
    for (final MotionPathTrackRuntime child in complete) {
      _reflows.remove(child);
    }
  }

  void _settle({bool drain = false}) {
    _seekChildren();
    if (drain) _drain();
    _rebuild();
    notifyListeners();
  }

  void _seekChildren() {
    for (final MotionPathTrackRuntime child in parent.children) {
      child.seek(_localProgress(child));
    }
  }

  void _drain() {
    final List<String> completed = <String>[];
    for (final MotionPathTrackRuntime child in parent.children) {
      if (_localProgress(child) >= 1) completed.add(child.id);
    }
    if (completed.isEmpty) return;
    for (final String childId in completed) parent.removeChild(childId);
    _seekChildren();
  }

  void _rebuild() {
    final List<MotionPathTrackRuntime> ordered = <MotionPathTrackRuntime>[];
    for (final MotionPathTrackRuntime child in parent.children) {
      int slot = ordered.length;
      while (slot > 0 &&
          _effectiveOffset(ordered[slot - 1]) > _effectiveOffset(child)) {
        slot--;
      }
      ordered.insert(slot, child);
    }
    _instances = List<MotionPathSpawnInstance>.unmodifiable(
      <MotionPathSpawnInstance>[
        for (final MotionPathTrackRuntime child in ordered)
          MotionPathSpawnInstance(
            id: child.id,
            offset: _effectiveOffset(child),
            progress: child.progress,
            hasStarted: _elapsed >= _effectiveOffset(child),
            patch: child.compose(),
          ),
      ],
    );
  }

  double _effectiveOffset(MotionPathTrackRuntime child) =>
      _reflows[child]?.value ?? child.currentOffset;

  double _spanOf(MotionPathTrackRuntime child) =>
      child.duration > 0
          ? child.duration
          : (childDuration > 0 ? childDuration : 1);

  double _localProgress(MotionPathTrackRuntime child) =>
      ((_elapsed - _effectiveOffset(child)) / _spanOf(child))
          .clamp(0.0, 1.0)
          .toDouble();

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
