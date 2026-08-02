import '../contract/motionpath_types.dart';

/// Validates plugin-owned keyframe payloads before runtime composition.
///
/// These checks belong at the project boundary. A malformed path or frame list
/// otherwise reaches a plugin that can only return an empty patch, which makes
/// an authored scene silently disappear.
List<MotionPathDiagnostic> keyframePayloadRules(
  Map<String, Object?> keyframes,
  String path,
) {
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  for (final MapEntry<String, Object?> entry in keyframes.entries) {
    final String propertyPath = '$path.keyframes.${entry.key}';
    final Map<String, Object?> config = asStringKeyedMap(entry.value);
    if (entry.key == 'path') {
      diagnostics.addAll(_pathRules(config, propertyPath));
    } else if (entry.key == 'imageSequence') {
      diagnostics.addAll(_imageSequenceRules(config, propertyPath));
    }
  }
  return diagnostics;
}

List<MotionPathDiagnostic> _pathRules(
  Map<String, Object?> config,
  String path,
) {
  final Object? rawPoints = config['points'];
  if (rawPoints is! List<Object?> || rawPoints.length < 2) {
    return <MotionPathDiagnostic>[
      MotionPathDiagnostic(
        path: '$path.points',
        code: 'path-shape',
        message: 'path.points must be an array with at least 2 points.',
      ),
    ];
  }
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  for (int index = 0; index < rawPoints.length; index++) {
    final Map<String, Object?> point = asStringKeyedMap(rawPoints[index]);
    if (point['x'] is! num) {
      diagnostics.add(
        MotionPathDiagnostic(
          path: '$path.points[$index].x',
          code: 'path-shape',
          message: 'Path point x must be numeric.',
        ),
      );
    }
    if (point['y'] is! num) {
      diagnostics.add(
        MotionPathDiagnostic(
          path: '$path.points[$index].y',
          code: 'path-shape',
          message: 'Path point y must be numeric.',
        ),
      );
    }
    for (final String control in <String>['ctrlX', 'ctrlY', 'ctrlZ']) {
      if (point.containsKey(control) && point[control] is! num) {
        diagnostics.add(
          MotionPathDiagnostic(
            path: '$path.points[$index].$control',
            code: 'path-shape',
            message: 'Path control $control must be numeric when present.',
          ),
        );
      }
    }
    if (point.containsKey('z') && point['z'] is! num) {
      diagnostics.add(
        MotionPathDiagnostic(
          path: '$path.points[$index].z',
          code: 'path-shape',
          message: 'Path point z must be numeric when present.',
        ),
      );
    }
  }
  return diagnostics;
}

List<MotionPathDiagnostic> _imageSequenceRules(
  Map<String, Object?> config,
  String path,
) {
  final Object? rawFrames = config['frames'];
  if (rawFrames is! List<Object?> || rawFrames.isEmpty) {
    return <MotionPathDiagnostic>[
      MotionPathDiagnostic(
        path: '$path.frames',
        code: 'image-sequence-shape',
        message: 'imageSequence.frames must be a non-empty array.',
      ),
    ];
  }
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  for (int index = 0; index < rawFrames.length; index++) {
    final Object? frame = rawFrames[index];
    if (frame is! String || frame.isEmpty) {
      diagnostics.add(
        MotionPathDiagnostic(
          path: '$path.frames[$index]',
          code: 'image-sequence-shape',
          message: 'Image sequence frames must be non-empty strings.',
        ),
      );
    }
  }
  return diagnostics;
}
