import 'package:meta/meta.dart';

import '../math/fk_math.dart';

/// Frame-time composition step: raw track state in, patch fragment out.
typedef PatchComposer = Map<String, Object?>? Function(
  Map<String, Object?> raw,
);

/// A property plugin.
///
/// [keys] are authored keyframe properties the plugin owns. [inputs] are
/// composed runtime values it consumes from observations. [outputs] are the
/// patch keys it writes, which is what makes collisions detectable before a
/// frame is ever composed. [internalKeys] never reach a renderer.
@immutable
class MotionPathPlugin {
  /// Creates a plugin.
  const MotionPathPlugin({
    required this.name,
    required this.compose,
    this.keys = const <String>[],
    this.inputs = const <String>[],
    this.outputs = const <String>[],
    this.internalKeys = const <String>[],
    this.stage = 0,
    this.priority = 0,
  });

  /// Stable plugin name.
  final String name;

  /// Frame-time composition function.
  final PatchComposer compose;

  /// Authored keyframe properties this plugin claims.
  final List<String> keys;

  /// Composed values this plugin consumes from observations.
  final List<String> inputs;

  /// Patch keys this plugin writes.
  final List<String> outputs;

  /// Keys that must never reach a renderer.
  final List<String> internalKeys;

  /// Coarse ordering bucket.
  final int stage;

  /// Fine ordering within a [stage].
  final int priority;

  /// Whether this plugin owns an authored [key].
  bool claimsKey(String key) => keys.contains(key);
}

double? _optionalDouble(Object? value) =>
    value is num ? value.toDouble() : null;

Map<String, Object?>? _composeForwardKinematics(Map<String, Object?> raw) {
  final double length = _optionalDouble(raw['boneLength']) ?? 0;
  final double rotation = _optionalDouble(raw['boneRotation']) ??
      _optionalDouble(raw['rotation']) ??
      0;
  final MotionPathWorldTransform world = composeWorld(
    worldFromInput(raw['parentWorld']),
    MotionPathWorldTransform(x: length, rotation: rotation),
  );
  return world.toPatch();
}

/// Forward-kinematics plugin.
///
/// A joint angle is authored as `boneRotation`, never `rotation`, because the
/// plugin already owns `rotation` as an output. Authoring both on one track is
/// an output collision, not a silent override.
const MotionPathPlugin forwardKinematicsPlugin = MotionPathPlugin(
  name: 'forward-kinematics',
  keys: <String>['boneLength', 'boneRotation'],
  inputs: <String>['parentWorld'],
  outputs: <String>['x', 'y', 'rotation'],
  internalKeys: <String>['boneLength', 'boneRotation', 'parentWorld'],
  stage: 10,
  compose: _composeForwardKinematics,
);

/// Creates a plugin that passes authored [keys] straight through to the patch.
MotionPathPlugin passthroughPlugin(List<String> keys) {
  final List<String> owned = List<String>.unmodifiable(keys);
  return MotionPathPlugin(
    name: 'property-passthrough',
    keys: owned,
    outputs: owned,
    compose: (Map<String, Object?> raw) => <String, Object?>{
      for (final String key in owned)
        if (raw.containsKey(key)) key: raw[key],
    },
  );
}

/// Resolves authored keyframe properties into an ordered plugin list.
class MotionPathPluginRegistry {
  /// Creates a registry. Defaults to the built-in plugins.
  MotionPathPluginRegistry({List<MotionPathPlugin>? plugins})
      : _plugins = List<MotionPathPlugin>.of(
          plugins ?? const <MotionPathPlugin>[forwardKinematicsPlugin],
        );

  final List<MotionPathPlugin> _plugins;

  /// Registered plugins, in registration order.
  List<MotionPathPlugin> get plugins =>
      List<MotionPathPlugin>.unmodifiable(_plugins);

  /// Registers an additional plugin.
  void register(MotionPathPlugin plugin) => _plugins.add(plugin);

  /// Resolves the plugins needed for [authoredKeys], in composition order.
  ///
  /// Any key no plugin claims falls back to a passthrough plugin, so authored
  /// data is never silently dropped.
  List<MotionPathPlugin> resolve(Iterable<String> authoredKeys) {
    final List<String> keys = List<String>.of(authoredKeys);
    final List<MotionPathPlugin> resolved = <MotionPathPlugin>[];
    final Set<String> claimed = <String>{};
    for (final MotionPathPlugin plugin in _plugins) {
      final List<String> matched =
          keys.where(plugin.claimsKey).toList(growable: false);
      if (matched.isEmpty) {
        continue;
      }
      resolved.add(plugin);
      claimed.addAll(matched);
    }
    final List<String> unclaimed = keys
        .where((String key) => !claimed.contains(key))
        .toList(growable: false);
    if (unclaimed.isNotEmpty) {
      resolved.add(passthroughPlugin(unclaimed));
    }
    resolved.sort((MotionPathPlugin a, MotionPathPlugin b) {
      final int byStage = a.stage.compareTo(b.stage);
      return byStage != 0 ? byStage : a.priority.compareTo(b.priority);
    });
    return List<MotionPathPlugin>.unmodifiable(resolved);
  }
}

/// Throws when two plugins on one track claim the same output key.
///
/// This is what stops an FK bone from stretching but never bending: authoring
/// `boneLength` next to `rotation` is rejected at mount time instead of
/// producing a silently wrong rig.
void assertOutputCompatibility(
  String trackId,
  List<MotionPathPlugin> plugins,
) {
  final Map<String, String> owners = <String, String>{};
  for (final MotionPathPlugin plugin in plugins) {
    for (final String output in plugin.outputs) {
      final String? existing = owners[output];
      if (existing != null && existing != plugin.name) {
        throw StateError('Output collision on track "$trackId" for "$output".');
      }
      owners[output] = plugin.name;
    }
  }
}
