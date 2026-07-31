import '../contract/motionpath_types.dart';

/// Validates a decoded project and returns every diagnostic found.
List<MotionPathDiagnostic> validateProject(Map<String, Object?> json) {
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  diagnostics.addAll(validateProjectStructure(json));
  diagnostics.addAll(validateFiniteProjectValues(json));
  diagnostics.addAll(validateProjectEasingNames(json));
  return List<MotionPathDiagnostic>.unmodifiable(diagnostics);
}

/// Returns only fatal diagnostics from [json].
List<MotionPathDiagnostic> fatalProjectDiagnostics(Map<String, Object?> json) =>
    validateProject(json)
        .where((MotionPathDiagnostic diagnostic) => diagnostic.isFatal)
        .toList(growable: false);
