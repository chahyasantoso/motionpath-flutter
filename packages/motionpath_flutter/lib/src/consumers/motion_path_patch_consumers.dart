import 'dart:ui' show ImageFilter;

/// Maximum blur sigma accepted at the renderer boundary.
const double kMotionPathMaxBlurSigma = 100;

/// Keys claimed by the generic Flutter renderer.
const Set<String> motionPathClaimedRendererKeys = <String>{
  'x',
  'y',
  'z',
  'translateX',
  'translateY',
  'translateZ',
  'rotation',
  'rotate',
  'rotationX',
  'rotateX',
  'rotationY',
  'rotateY',
  'scale',
  'scaleX',
  'scaleY',
  'scaleZ',
  'perspective',
  'opacity',
  'color',
  'visible',
  'filter',
  'image',
  'cssVariables',
  'instances',
};

/// Renderer keys that are known but intentionally not interpreted by Flutter.
/// They remain available to host builders or other platform renderers.
const Set<String> motionPathUnsupportedRendererKeys = <String>{};

/// Returns claimed renderer keys present in [patch] that are unsupported.
Set<String> motionPathUnsupportedKeys(Map<String, Object?> patch) {
  return <String>{
    for (final String key in patch.keys)
      if (motionPathClaimedRendererKeys.contains(key) &&
          motionPathUnsupportedRendererKeys.contains(key))
        key,
  };
}

/// A renderer-ready view of the non-visual patch payloads.
class MotionPathPatchConsumers {
  const MotionPathPatchConsumers._();

  static Object? imageFrame(Map<String, Object?> patch) => patch['image'];

  static Map<String, Object?> cssVariables(Map<String, Object?> patch) {
    final Object? raw = patch['cssVariables'];
    if (raw is! Map<Object?, Object?>) return const <String, Object?>{};
    final Map<String, Object?> result = <String, Object?>{};
    raw.forEach((Object? key, Object? value) {
      if (key is String && key.startsWith('--')) result[key] = value;
    });
    return result;
  }

  static ImageFilter? blurFilter(Map<String, Object?> patch) {
    final Object? raw = patch['filter'];
    if (raw is! Map<Object?, Object?>) return null;
    final Object? value = raw['blur'];
    if (value is! num) return null;
    final double sigma = value.toDouble();
    if (!sigma.isFinite || sigma <= 0) return null;
    final double bounded = sigma.clamp(0, kMotionPathMaxBlurSigma).toDouble();
    return ImageFilter.blur(sigmaX: bounded, sigmaY: bounded);
  }

  static List<Map<String, Object?>> instances(Map<String, Object?> patch) {
    final Object? raw = patch['instances'];
    if (raw is! List<Object?>) return const <Map<String, Object?>>[];
    final List<Map<String, Object?>> result = <Map<String, Object?>>[];
    for (final Object? entry in raw) {
      if (entry is! Map<Object?, Object?>) continue;
      final Map<String, Object?> normalized = <String, Object?>{};
      for (final MapEntry<Object?, Object?> item in entry.entries) {
        if (item.key is String) normalized[item.key as String] = item.value;
      }
      result.add(normalized);
    }
    return result;
  }
}
