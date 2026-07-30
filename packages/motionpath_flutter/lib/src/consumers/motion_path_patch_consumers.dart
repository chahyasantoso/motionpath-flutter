import 'dart:ui' show ImageFilter;

/// A renderer-ready view of the non-visual patch payloads.
class MotionPathPatchConsumers {
  const MotionPathPatchConsumers._();

  static Object? imageFrame(Map<String, Object?> patch) => patch['image'];

  static Map<String, Object?> cssVariables(Map<String, Object?> patch) {
    final Object? raw = patch['cssVariables'];
    if (raw is! Map<Object?, Object?>) {
      return const <String, Object?>{};
    }
    final Map<String, Object?> result = <String, Object?>{};
    raw.forEach((Object? key, Object? value) {
      if (key is String && key.startsWith('--')) {
        result[key] = value;
      }
    });
    return result;
  }

  static ImageFilter? blurFilter(Map<String, Object?> patch) {
    final Object? raw = patch['filter'];
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final Object? value = raw['blur'];
    if (value is! num) {
      return null;
    }
    final double sigma = value.toDouble();
    return sigma > 0 ? ImageFilter.blur(sigmaX: sigma, sigmaY: sigma) : null;
  }

  static List<Map<String, Object?>> instances(
    Map<String, Object?> patch,
  ) {
    final Object? raw = patch['instances'];
    if (raw is! List<Object?>) {
      return const <Map<String, Object?>>[];
    }
    final List<Map<String, Object?>> result = <Map<String, Object?>>[];
    for (final Object? entry in raw) {
      if (entry is! Map<Object?, Object?>) {
        continue;
      }
      final Map<String, Object?> normalized = <String, Object?>{};
      for (final MapEntry<Object?, Object?> item in entry.entries) {
        final Object? key = item.key;
        if (key is String) {
          normalized[key] = item.value;
        }
      }
      result.add(normalized);
    }
    return result;
  }
}
