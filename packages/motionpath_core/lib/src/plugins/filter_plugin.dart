import 'motionpath_plugin.dart';

/// Normalizes numeric filter properties without depending on a renderer.
const MotionPathPlugin filterPlugin = MotionPathPlugin(
  name: 'filter-group',
  keys: <String>['filter'],
  inputs: <String>['filter'],
  outputs: <String>['filter'],
  internalKeys: <String>['filterInput'],
  stage: 30,
  compose: _composeFilter,
);

const Set<String> _supportedFilters = <String>{
  'blur',
  'brightness',
  'contrast',
  'grayscale',
  'opacity',
  'saturate',
};

Map<String, Object?>? _composeFilter(Map<String, Object?> raw) {
  final Object? value = raw['filter'];
  if (value is! Map<Object?, Object?>) {
    return null;
  }
  final Map<String, Object?> normalized = <String, Object?>{};
  value.forEach((Object? key, Object? entry) {
    if (key is String && _supportedFilters.contains(key) && entry is num) {
      normalized[key] = entry.toDouble();
    }
  });
  return normalized.isEmpty ? null : <String, Object?>{'filter': normalized};
}
