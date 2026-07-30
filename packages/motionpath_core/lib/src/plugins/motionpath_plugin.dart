import 'package:meta/meta.dart';

import '../math/fk_math.dart';

typedef PatchComposer = Map<String, Object?>? Function(
  Map<String, Object?> raw,
);

@immutable
class MotionPathPlugin {
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

  final String name;
  final PatchComposer compose;
  final List<String> keys;
  final List<String> inputs;
  final List<String> outputs;
  final List<String> internalKeys;
  final int stage;
  final int priority;

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

const MotionPathPlugin forwardKinematicsPlugin = MotionPathPlugin(
  name: 'forward-kinematics',
  keys: <String>['boneLength', 'boneRotation'],
  inputs: <String>['parentWorld'],
  outputs: <String>['x', 'y', 'rotation'],
  internalKeys: <String>['boneLength', 'boneRotation', 'parentWorld'],
  stage: 10,
  compose: _composeForwardKinematics,
);

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

/// Throws when a plugin's declaration is internally inconsistent.
void assertPluginContract(MotionPathPlugin plugin) {
  if (plugin.name.trim().isEmpty) {
    throw StateError('Plugin name must not be empty.');
  }
  final Set<String> outputs = <String>{};
  for (final String output in plugin.outputs) {
    if (output.isEmpty || !outputs.add(output)) {
      throw StateError('Plugin "${plugin.name}" declares duplicate or empty outputs.');
    }
  }
  final Set<String> internal = plugin.internalKeys.toSet();
  if (!internal.containsAll(plugin.internalKeys)) {
    throw StateError('Plugin "${plugin.name}" has invalid internal keys.');
  }
  if (plugin.internalKeys.any((String key) => key.isEmpty)) {
    throw StateError('Plugin "${plugin.name}" declares an empty internal key.');
  }
}

class MotionPathPluginRegistry {
  MotionPathPluginRegistry({List<MotionPathPlugin>? plugins})
      : _plugins = <MotionPathPlugin>[] {
    for (final MotionPathPlugin plugin
        in plugins ?? const <MotionPathPlugin>[forwardKinematicsPlugin]) {
      register(plugin);
    }
  }

  final List<MotionPathPlugin> _plugins;

  List<MotionPathPlugin> get plugins =>
      List<MotionPathPlugin>.unmodifiable(_plugins);

  void register(MotionPathPlugin plugin) {
    assertPluginContract(plugin);
    if (_plugins.any((MotionPathPlugin existing) => existing.name == plugin.name)) {
      throw StateError('Plugin "${plugin.name}" is already registered.');
    }
    _plugins.add(plugin);
  }

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
