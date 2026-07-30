import '../plugins/motionpath_plugin.dart';

/// Merges [b] over [a], shallow-merging nested object values.
Map<String, Object?> mergePatches(
  Map<String, Object?>? a,
  Map<String, Object?>? b,
) {
  if (a == null) {
    return b ?? <String, Object?>{};
  }
  if (b == null) {
    return a;
  }
  final Map<String, Object?> merged = <String, Object?>{...a};
  b.forEach((String key, Object? value) {
    final Object? existing = merged[key];
    if (value is Map<String, Object?> && existing is Map<String, Object?>) {
      merged[key] = <String, Object?>{...existing, ...value};
    } else {
      merged[key] = value;
    }
  });
  return merged;
}

/// Folds every plugin contribution into one renderer-neutral patch.
///
/// Internal keys declared by any plugin are stripped, so proxy-only state can
/// never leak into a renderer.
Map<String, Object?> composePatch(
  List<MotionPathPlugin> plugins,
  Map<String, Object?> raw,
) {
  if (plugins.isEmpty) {
    return <String, Object?>{};
  }
  final Set<String> internalKeys = <String>{
    for (final MotionPathPlugin plugin in plugins) ...plugin.internalKeys,
  };
  final Map<String, Object?> patch = <String, Object?>{};
  for (final MotionPathPlugin plugin in plugins) {
    final Map<String, Object?>? contribution = plugin.compose(raw);
    if (contribution == null) {
      continue;
    }
    contribution.forEach((String key, Object? value) {
      if (internalKeys.contains(key)) {
        return;
      }
      patch[key] = value;
    });
  }
  return patch;
}
