import '../contract/motionpath_types.dart';

List<MotionPathDiagnostic> validateProject(Map<String, Object?> json) {
  try {
    MotionPathProject.fromJson(json);
    return const <MotionPathDiagnostic>[];
  } on MotionPathValidationException catch (error) {
    return error.diagnostics;
  }
}

void assertValidProject(Map<String, Object?> json) {
  final diagnostics = validateProject(json);
  if (diagnostics.isNotEmpty) throw MotionPathValidationException(diagnostics);
}
