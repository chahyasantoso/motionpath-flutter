import 'motionpath_plugin.dart';

/// Preserves an authored overlay payload for a renderer or scene adapter.
const MotionPathPlugin overlayPlugin = MotionPathPlugin(
  name: 'overlay',
  keys: <String>['overlay'],
  inputs: <String>['overlay'],
  outputs: <String>['overlay'],
  internalKeys: <String>['overlayInput'],
  stage: 40,
  compose: _composeOverlay,
);

/// Expands a static spawner payload into renderer-neutral instance records.
const MotionPathPlugin spawnerPlugin = MotionPathPlugin(
  name: 'spawner',
  keys: <String>['spawner'],
  inputs: <String>['spawner'],
  outputs: <String>['instances'],
  internalKeys: <String>['spawner'],
  stage: 40,
  compose: _composeSpawner,
);

Map<String, Object?>? _composeOverlay(Map<String, Object?> raw) {
  final Object? value = raw['overlay'];
  if (value is! Map<Object?, Object?>) {
    return null;
  }
  final Map<String, Object?> result = <String, Object?>{};
  value.forEach((Object? key, Object? entry) {
    if (key is String && key.isNotEmpty) {
      result[key] = entry;
    }
  });
  return result.isEmpty ? null : <String, Object?>{'overlay': result};
}

Map<String, Object?>? _composeSpawner(Map<String, Object?> raw) {
  final Object? value = raw['spawner'];
  if (value is! Map<Object?, Object?>) {
    return null;
  }
  final Object? countValue = value['count'];
  final int count = countValue is num ? countValue.floor().clamp(0, 1000) : 0;
  final Object? template = value['template'];
  if (count == 0 || template == null) {
    return null;
  }
  return <String, Object?>{
    'instances': <Map<String, Object?>>[
      for (int index = 0; index < count; index++)
        <String, Object?>{'index': index, 'template': template},
    ],
  };
}
