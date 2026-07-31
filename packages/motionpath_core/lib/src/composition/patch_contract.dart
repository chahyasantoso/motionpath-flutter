import '../plugins/motionpath_plugin.dart';
import 'immutable_patch.dart';

/// Classification for keys crossing the core-to-renderer patch boundary.
enum MotionPathPatchKeyKind {
  /// A value intended for a host renderer or consumer.
  publicOutput,

  /// A value used only while composing plugins and observations.
  internal,

  /// A value describing renderer behavior without being an authored property.
  rendererMetadata,

  /// A payload owned by a registered plugin.
  pluginPayload,
}

/// Shared key and snapshot rules for renderer-neutral patches.
class MotionPathPatchContract {
  const MotionPathPatchContract._();

  /// Keys used by composition internals and never exposed to renderers.
  static const Set<String> internalKeys = <String>{
    'progress',
    'boneLength',
    'boneRotation',
    'parentWorld',
  };

  /// Renderer metadata may be consumed by a host but is not an authored style.
  static const Set<String> rendererMetadataKeys = <String>{
    'z',
    'perspective',
    'visible',
  };

  /// Returns the stable category for a patch key.
  static MotionPathPatchKeyKind classify(
    String key, {
    Iterable<MotionPathPlugin> plugins = const <MotionPathPlugin>[],
  }) {
    if (internalKeys.contains(key) ||
        plugins.any((MotionPathPlugin plugin) => plugin.internalKeys.contains(key))) {
      return MotionPathPatchKeyKind.internal;
    }
    if (rendererMetadataKeys.contains(key)) {
      return MotionPathPatchKeyKind.rendererMetadata;
    }
    if (plugins.any((MotionPathPlugin plugin) => plugin.outputs.contains(key))) {
      return MotionPathPatchKeyKind.pluginPayload;
    }
    return MotionPathPatchKeyKind.publicOutput;
  }

  /// Removes internal keys and recursively freezes the public snapshot.
  static Map<String, Object?> normalize(
    Map<String, Object?> patch, {
    Iterable<MotionPathPlugin> plugins = const <MotionPathPlugin>[],
  }) {
    final Map<String, Object?> publicPatch = <String, Object?>{};
    for (final MapEntry<String, Object?> entry in patch.entries) {
      if (classify(entry.key, plugins: plugins) == MotionPathPatchKeyKind.internal) {
        continue;
      }
      publicPatch[entry.key] = entry.value;
    }
    return immutablePatch(publicPatch);
  }
}
