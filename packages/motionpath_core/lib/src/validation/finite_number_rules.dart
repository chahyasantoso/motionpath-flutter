import '../contract/motionpath_types.dart';

/// Validates numeric fields that would otherwise poison interpolation or paint.
List<MotionPathDiagnostic> finiteNumberRules(Map<String, Object?> json) {
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  _finite(json['perspective'], r'$.perspective', diagnostics);
  final Object? rawMotions = json['motions'];
  if (rawMotions is List<Object?>) {
    for (int motionIndex = 0; motionIndex < rawMotions.length; motionIndex++) {
      final Map<String, Object?> motion = asStringKeyedMap(rawMotions[motionIndex]);
      final String motionPath = 'motions[$motionIndex]';
      _finite(motion['stagger'], '$motionPath.stagger', diagnostics);
      final Map<String, Object?> trigger = asStringKeyedMap(motion['trigger']);
      _finite(trigger['repeatDelay'], '$motionPath.trigger.repeatDelay', diagnostics);
      _finite(trigger['delay'], '$motionPath.trigger.delay', diagnostics);
      _finite(trigger['scrub'], '$motionPath.trigger.scrub', diagnostics);
      final Object? rawTracks = motion['tracks'];
      if (rawTracks is List<Object?>) {
        for (int trackIndex = 0; trackIndex < rawTracks.length; trackIndex++) {
          _trackFinite(
            asStringKeyedMap(rawTracks[trackIndex]),
            '$motionPath.tracks[$trackIndex]',
            diagnostics,
          );
        }
      }
    }
  }
  final Object? rawTracks = json['tracks'];
  if (rawTracks is List<Object?>) {
    for (int index = 0; index < rawTracks.length; index++) {
      _trackFinite(asStringKeyedMap(rawTracks[index]), 'tracks[$index]', diagnostics);
    }
  }
  return diagnostics;
}

void _trackFinite(
  Map<String, Object?> track,
  String path,
  List<MotionPathDiagnostic> diagnostics,
) {
  _finite(track['duration'], '$path.duration', diagnostics);
  final Map<String, Object?> keyframes = asStringKeyedMap(track['keyframes']);
  for (final MapEntry<String, Object?> entry in keyframes.entries) {
    final Map<String, Object?> config = asStringKeyedMap(entry.value);
    final Object? rawStops = config['stops'];
    if (rawStops is! List<Object?>) continue;
    for (int index = 0; index < rawStops.length; index++) {
      final Map<String, Object?> stop = asStringKeyedMap(rawStops[index]);
      _finite(stop['p'], '$path.keyframes.${entry.key}.stops[$index].p', diagnostics);
      _finite(stop['v'], '$path.keyframes.${entry.key}.stops[$index].v', diagnostics);
    }
  }
}

void _finite(Object? value, String path, List<MotionPathDiagnostic> diagnostics) {
  if (value is num && !value.toDouble().isFinite) {
    diagnostics.add(MotionPathDiagnostic(
      path: path,
      code: 'finite-number',
      message: 'Numeric values must be finite.',
    ));
  }
}
