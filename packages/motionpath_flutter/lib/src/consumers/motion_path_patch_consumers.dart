import 'dart:ui' show ImageFilter;

/// A renderer-ready view of the non-visual patch payloads.
///
/// Image loading, CSS application, and scene ownership stay with the host app;
/// this adapter only translates the pure Dart patch shape into safe Flutter
/// values and bounded instance descriptors.
class MotionPathPatchConsumers {
  const MotionPathPatchConsumers._();

  /// Returns the authored image frame reference, if present.
  static Object? imageFrame(Map<String, Object?> patch) => patch['image'];

  /// Returns valid CSS custom properties for a platform adapter.
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

  /// Converts a numeric blur filter into Flutter's image filter.
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
    if (sigma <= 0) {
      return null;
    }
    return ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
  }

  /// Returns bounded Spawner instance records for a scene adapter.
  static List<Map<String, Object?>> instances(
    Map<String, Object?> patch,
  ) {
    final Object? raw = patch['instances'];
    if (raw is! List<Object?>) {
      return const <Map<String, Object?>>[];
    }
    return <Map<String, Object?>>[
      for (final Object? entry in raw)
        if (entry is Map<Object?, Object?>)
          <String, Object?>{
            for (final MapEntry<Object?, Object?> item in entry.entries)
              if (item.key is String) item.key! as String: item.value,
          },
    ];
  }
}
