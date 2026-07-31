/// Deep structural equality for composed MotionPath patches.
///
/// Patches are plain nested Dart data: maps of maps, lists of maps, numbers,
/// strings, and booleans. `mapEquals` only compares one level, so a patch whose
/// `filter`, `cssVariables`, `instances`, or `image` payload changed while the
/// top-level keys stayed identical would compare equal and silently skip a
/// repaint. Dirty checking at the renderer boundary therefore needs this
/// recursive comparison.
///
/// Two NaN values compare equal on purpose. A patch carrying NaN would
/// otherwise never settle and would invalidate every frame forever.
bool motionPathPatchEquals(Object? a, Object? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a is Map<Object?, Object?> && b is Map<Object?, Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (final MapEntry<Object?, Object?> entry in a.entries) {
      if (!b.containsKey(entry.key)) {
        return false;
      }
      if (!motionPathPatchEquals(entry.value, b[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (int index = 0; index < a.length; index++) {
      if (!motionPathPatchEquals(a[index], b[index])) {
        return false;
      }
    }
    return true;
  }
  if (a is double && b is double && a.isNaN && b.isNaN) {
    return true;
  }
  return a == b;
}
