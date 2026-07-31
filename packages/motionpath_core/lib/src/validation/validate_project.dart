import '../contract/motionpath_types.dart';
import 'easing_rules.dart';
import 'finite_number_rules.dart';
import 'project_rules.dart';

/// Validates a decoded v4 project and collects every diagnostic.
List<MotionPathDiagnostic> validateProject(Map<String, Object?> json) {
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  diagnostics.addAll(schemaVersionRule(json));
  diagnostics.addAll(finiteNumberRules(json));

  final Object? rawMotions = json['motions'];
  if (rawMotions is! List<Object?>) {
    diagnostics.add(const MotionPathDiagnostic(path: r'$.motions', code: 'invalid-shape', message: 'schema.motions must be an array.'));
    return List<MotionPathDiagnostic>.unmodifiable(diagnostics);
  }

  diagnostics.addAll(perspectiveUsageRule(json));
  diagnostics.addAll(motionStructureRule(json));
  final List<Map<String, Object?>> templates = asStringKeyedMapList(json['templates']);
  for (int index = 0; index < rawMotions.length; index++) {
    final Map<String, Object?> motion = asStringKeyedMap(rawMotions[index]);
    if (motion.isEmpty) continue;
    final String motionPath = 'motions[$index]';
    diagnostics.addAll(triggerShapeRule(motion, motionPath));
    final MotionPathMotion parsed = MotionPathMotion.fromJson(motion, templates: templates);
    for (int trackIndex = 0; trackIndex < parsed.tracks.length; trackIndex++) {
      final MotionPathTrack track = parsed.tracks[trackIndex];
      final Map<String, Object?> trackJson = <String, Object?>{'id': track.id, 'keyframes': track.keyframes};
      diagnostics.addAll(trackKeyframeRules(trackJson, '$motionPath.tracks[$trackIndex]'));
      diagnostics.addAll(easingRules(trackJson, '$motionPath.tracks[$trackIndex]'));
    }
    diagnostics.addAll(trackObservationsRule(parsed, motionPath));
  }

  final Object? rawTracks = json['tracks'];
  if (rawTracks is List<Object?>) {
    for (int index = 0; index < rawTracks.length; index++) {
      final MotionPathTrack track = MotionPathTrack.fromJson(asStringKeyedMap(rawTracks[index]), templates: templates);
      final Map<String, Object?> trackJson = <String, Object?>{'id': track.id, 'keyframes': track.keyframes};
      diagnostics.addAll(trackKeyframeRules(trackJson, 'tracks[$index]'));
      diagnostics.addAll(easingRules(trackJson, 'tracks[$index]'));
    }
  }
  return List<MotionPathDiagnostic>.unmodifiable(diagnostics);
}

bool hasFatalErrors(List<MotionPathDiagnostic> diagnostics) => diagnostics.any((MotionPathDiagnostic diagnostic) => diagnostic.isFatal);

void assertValidProject(Map<String, Object?> json) {
  final List<MotionPathDiagnostic> diagnostics = validateProject(json);
  final List<MotionPathDiagnostic> fatal = diagnostics.where((MotionPathDiagnostic diagnostic) => diagnostic.isFatal).toList(growable: false);
  if (fatal.isNotEmpty) {
    throw MotionPathValidationException(List<MotionPathDiagnostic>.unmodifiable(fatal));
  }
}
