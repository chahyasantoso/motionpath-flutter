import '../plugins/motionpath_plugin.dart';
import 'immutable_patch.dart';
import 'patch_contract.dart';

/// Merges [b] over [a], shallow-merging nested object values.
Map<String, Object?> mergePatches(
  Map<String, Object?>? a,
  Map<String, Object?>? b,
) {
  if (a == null) return MotionPathPatchContract.normalize(b ?? <String, Object?>{});
  if (b == null) return MotionPathPatchContract.normalize(a);
  final Map<String, Object?> merged = <String, Object?>{...a};
  b.forEach((String key, Object? value) {
    final Object? existing = merged[key];
    if (value is Map<String, Object?> && existing is Map<String, Object?>) {
      merged[key] = <String, Object?>{...existing, ...value};
    } else {
      merged[key] = value;
    }
  });
  return MotionPathPatchContract.normalize(merged);
}

/// Folds every plugin contribution into one renderer-neutral patch.
Map<String, Object?> composePatch(
  List<MotionPathPlugin> plugins,
  Map<String, Object?> raw,
) {
  if (plugins.isEmpty) return MotionPathPatchContract.normalize(raw);
  final Set<String> internalKeys = <String>{
    for (final MotionPathPlugin plugin in plugins) ...plugin.internalKeys,
  };
  final Map<String, Object?> patch = <String, Object?>{};
  for (final MotionPathPlugin plugin in plugins) {
    final Map<String, Object?>? contribution = plugin.compose(raw);
    if (contribution == null) continue;
    contribution.forEach((String key, Object? value) {
      if (internalKeys.contains(key)) return;
      patch[key] = value;
    });
  }
  return MotionPathPatchContract.normalize(patch, plugins: plugins);
}
