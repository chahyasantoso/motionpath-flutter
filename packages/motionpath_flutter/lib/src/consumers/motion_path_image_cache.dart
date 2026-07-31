import 'package:flutter/widgets.dart';

/// Builds a framework object for one renderer-neutral image frame identifier.
typedef MotionPathImageFrameLoader<T> = T Function(Object frame);

/// Releases a cached host resource.
typedef MotionPathImageFrameDisposer<T> = void Function(T resource);

/// Host-owned cache for resolved image frame resources.
///
/// The core only publishes an immutable frame identifier. This cache keeps
/// loading, reuse, eviction, and disposal in Flutter or the host application,
/// where resource ownership belongs. It never assumes that a frame is an
/// `ImageProvider`, and it never disposes a resource unless the host asks it to.
class MotionPathImageFrameCache<T> {
  final Map<Object, T> _entries = <Object, T>{};
  bool _disposed = false;

  /// Number of retained frame resources.
  int get length => _entries.length;

  /// Returns a cached resource or loads it once for [frame].
  T resolve(Object frame, MotionPathImageFrameLoader<T> loader) {
    if (_disposed) {
      throw StateError('MotionPathImageFrameCache is disposed.');
    }
    return _entries.putIfAbsent(frame, () => loader(frame));
  }

  /// Evicts one frame and optionally releases its host resource.
  bool evict(Object frame, {MotionPathImageFrameDisposer<T>? dispose}) {
    final T? resource = _entries.remove(frame);
    if (resource == null) {
      return false;
    }
    dispose?.call(resource);
    return true;
  }

  /// Releases all retained resources and prevents future resolution.
  void dispose({MotionPathImageFrameDisposer<T>? dispose}) {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (dispose != null) {
      for (final T resource in _entries.values) {
        dispose(resource);
      }
    }
    _entries.clear();
  }
}

/// A small adapter for hosts that cache widgets rather than decoded images.
///
/// Use only with immutable or otherwise safely reusable widgets. Stateful image
/// ownership should use [MotionPathImageFrameCache] with an explicit disposer.
class MotionPathCachedImageFrame extends StatelessWidget {
  const MotionPathCachedImageFrame({required this.frame, required this.child, super.key});

  final Object frame;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
