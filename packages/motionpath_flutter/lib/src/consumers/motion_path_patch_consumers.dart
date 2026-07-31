import 'dart:ui' show ImageFilter;

/// Maximum blur sigma accepted at the renderer boundary.
///
/// Large or non-finite values can create excessive GPU work. The renderer
/// ignores invalid values and clamps valid values to this bound.
const double kMotionPathMaxBlurSigma = 100;

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

  /// Resolves a bounded blur filter.
  ///
  /// Missing, negative, NaN, and infinite values mean no blur. Finite values
  /// above [kMotionPathMaxBlurSigma] are clamped rather than passed unchecked
  /// to the compositor.
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
    if (!sigma.isFinite || sigma <= 0) {
      return null;
    }
    return ImageFilter.blur(
      sigmaX: sigma.clamp(0, kMotionPathMaxBlurSigma).toDouble(),
      sigmaY: sigma.clamp(0, kMotionPathMaxBlurSigma).toDouble(),
    );
  }

  static List<Map<String, Object?>> instances(Map<String, Object?> patch) {
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
