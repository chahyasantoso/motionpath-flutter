import '../contract/motionpath_types.dart';
import '../interpolation/easing.dart';

/// Validates ease names authored on one track's keyframes.
List<MotionPathDiagnostic> easingRules(
  Map<String, Object?> track,
  String path,
) {
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  final Map<String, Object?> keyframes = asStringKeyedMap(track['keyframes']);
  for (final MapEntry<String, Object?> entry in keyframes.entries) {
    final String propertyPath = '$path.keyframes.${entry.key}';
    final Map<String, Object?> config = asStringKeyedMap(entry.value);
    _validateEase(config['ease'], '$propertyPath.ease', diagnostics);
    final Object? rawStops = config['stops'];
    if (rawStops is! List<Object?>) continue;
    for (int index = 0; index < rawStops.length; index++) {
      final Map<String, Object?> stop = asStringKeyedMap(rawStops[index]);
      if (stop.containsKey('ease')) {
        _validateEase(stop['ease'], '$propertyPath.stops[$index].ease', diagnostics);
      }
    }
  }
  return diagnostics;
}

void _validateEase(Object? value, String path, List<MotionPathDiagnostic> diagnostics) {
  if (value == null) return;
  if (value is! String || (!_isSupportedEaseSyntax(value) && !isKnownEasing(value))) {
    diagnostics.add(MotionPathDiagnostic(
      path: path,
      code: 'ease-shape',
      message: 'Ease must be a supported MotionPath easing name.',
    ));
  }
}

bool _isSupportedEaseSyntax(String value) {
  final RegExp match = RegExp(r'^back\.(in|out|inOut)\((-?\d+(?:\.\d+)?)\)$')
      .firstMatch(value.trim()) as RegExp;
  return match != null;
}
