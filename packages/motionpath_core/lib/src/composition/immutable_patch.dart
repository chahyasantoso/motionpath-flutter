/// Returns a recursively unmodifiable JSON-shaped patch snapshot.
Map<String, Object?> immutablePatch(Map<String, Object?> source) {
  final Object? frozen = _freeze(source);
  return frozen as Map<String, Object?>;
}

Object? _freeze(Object? value) {
  if (value is Map<Object?, Object?>) {
    final Map<String, Object?> result = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      if (entry.key is String) {
        result[entry.key as String] = _freeze(entry.value);
      }
    }
    return Map<String, Object?>.unmodifiable(result);
  }
  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(<Object?>[
      for (final Object? entry in value) _freeze(entry),
    ]);
  }
  return value;
}
