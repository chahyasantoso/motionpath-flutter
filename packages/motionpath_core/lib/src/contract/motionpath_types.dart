import 'dart:convert';

class MotionPathValidationException implements Exception {
  const MotionPathValidationException(this.diagnostics);

  final List<MotionPathDiagnostic> diagnostics;

  @override
  String toString() => diagnostics.map((d) => d.toString()).join('\n');
}

class MotionPathDiagnostic {
  const MotionPathDiagnostic({required this.path, required this.code, required this.message});

  final String path;
  final String code;
  final String message;

  @override
  String toString() => '$path [$code]: $message';
}

class MotionPathProject {
  const MotionPathProject({
    required this.schemaVersion,
    required this.projectId,
    this.perspective,
    this.templates = const <Map<String, Object?>>[],
    this.motions = const <MotionPathMotion>[],
    this.tracks = const <MotionPathTrack>[],
  });

  final int schemaVersion;
  final String? projectId;
  final num? perspective;
  final List<Map<String, Object?>> templates;
  final List<MotionPathMotion> motions;
  final List<MotionPathTrack> tracks;

  factory MotionPathProject.fromJson(Map<String, Object?> json) {
    final diagnostics = <MotionPathDiagnostic>[];
    final version = json['schemaVersion'];
    if (version is! int) {
      diagnostics.add(const MotionPathDiagnostic(path: 'schemaVersion', code: 'required', message: 'Must be an integer.'));
    } else if (version != 4) {
      diagnostics.add(const MotionPathDiagnostic(path: 'schemaVersion', code: 'unsupported', message: 'Only schema version 4 is supported.'));
    }

    final projectId = json['projectId'];
    if (projectId != null && projectId is! String) {
      diagnostics.add(const MotionPathDiagnostic(path: 'projectId', code: 'type', message: 'Must be a string.'));
    }

    final perspective = json['perspective'];
    if (perspective != null && perspective is! num) {
      diagnostics.add(const MotionPathDiagnostic(path: 'perspective', code: 'type', message: 'Must be numeric.'));
    }

    final motions = <MotionPathMotion>[];
    final rawMotions = json['motions'];
    if (rawMotions is! List) {
      diagnostics.add(const MotionPathDiagnostic(path: 'motions', code: 'required', message: 'Must be an array.'));
    } else {
      for (var i = 0; i < rawMotions.length; i++) {
        final value = rawMotions[i];
        if (value is Map) {
          motions.add(MotionPathMotion.fromJson(Map<String, Object?>.from(value), 'motions[$i]', diagnostics));
        } else {
          diagnostics.add(MotionPathDiagnostic(path: 'motions[$i]', code: 'type', message: 'Must be an object.'));
        }
      }
    }

    final libraryTracks = parseTrackList(json['tracks'], 'tracks', diagnostics);

    if (diagnostics.isNotEmpty) throw MotionPathValidationException(List.unmodifiable(diagnostics));
    return MotionPathProject(
      schemaVersion: version as int,
      projectId: projectId as String?,
      perspective: perspective as num?,
      motions: List.unmodifiable(motions),
      tracks: libraryTracks,
    );
  }

  factory MotionPathProject.fromJsonString(String source) => MotionPathProject.fromJson(
        Map<String, Object?>.from(jsonDecode(source) as Map),
      );
}

/// Parses an optional array of track objects, collecting diagnostics.
List<MotionPathTrack> parseTrackList(Object? raw, String path, List<MotionPathDiagnostic> diagnostics) {
  if (raw == null) return const <MotionPathTrack>[];
  if (raw is! List) {
    diagnostics.add(MotionPathDiagnostic(path: path, code: 'type', message: 'Must be an array.'));
    return const <MotionPathTrack>[];
  }
  final parsed = <MotionPathTrack>[];
  for (var i = 0; i < raw.length; i++) {
    final value = raw[i];
    if (value is Map) {
      parsed.add(MotionPathTrack.fromJson(Map<String, Object?>.from(value), '$path[$i]', diagnostics));
    } else {
      diagnostics.add(MotionPathDiagnostic(path: '$path[$i]', code: 'type', message: 'Must be an object.'));
    }
  }
  return List<MotionPathTrack>.unmodifiable(parsed);
}

class MotionPathMotion {
  const MotionPathMotion({required this.id, required this.trigger, this.tracks = const <MotionPathTrack>[]});

  final String id;
  final Map<String, Object?> trigger;
  final List<MotionPathTrack> tracks;

  factory MotionPathMotion.fromJson(Map<String, Object?> json, String path, List<MotionPathDiagnostic> diagnostics) {
    final id = json['id'];
    if (id is! String || id.isEmpty) diagnostics.add(MotionPathDiagnostic(path: '$path.id', code: 'required', message: 'Must be a non-empty string.'));
    final trigger = json['trigger'];
    if (trigger is! Map) diagnostics.add(MotionPathDiagnostic(path: '$path.trigger', code: 'required', message: 'Must be an object.'));
    return MotionPathMotion(
      id: id is String ? id : '',
      trigger: trigger is Map ? Map<String, Object?>.from(trigger) : const <String, Object?>{},
      tracks: parseTrackList(json['tracks'], '$path.tracks', diagnostics),
    );
  }
}

class MotionPathTrack {
  const MotionPathTrack({required this.id, this.duration, this.keyframes = const <String, Object?>{}, this.observes = const <Map<String, Object?>>[]});

  final String id;
  final num? duration;
  final Map<String, Object?> keyframes;
  final List<Map<String, Object?>> observes;

  factory MotionPathTrack.fromJson(Map<String, Object?> json, String path, List<MotionPathDiagnostic> diagnostics) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      diagnostics.add(MotionPathDiagnostic(path: '$path.id', code: 'required', message: 'Must be a non-empty string.'));
    }

    final duration = json['duration'];
    if (duration != null && duration is! num) {
      diagnostics.add(MotionPathDiagnostic(path: '$path.duration', code: 'type', message: 'Must be numeric.'));
    }

    final keyframes = json['keyframes'];
    if (keyframes != null && keyframes is! Map) {
      diagnostics.add(MotionPathDiagnostic(path: '$path.keyframes', code: 'type', message: 'Must be an object.'));
    }

    final observes = <Map<String, Object?>>[];
    final rawObserves = json['observes'];
    if (rawObserves != null) {
      if (rawObserves is! List) {
        diagnostics.add(MotionPathDiagnostic(path: '$path.observes', code: 'type', message: 'Must be an array.'));
      } else {
        for (var i = 0; i < rawObserves.length; i++) {
          final entry = rawObserves[i];
          if (entry is Map) {
            observes.add(Map<String, Object?>.from(entry));
          } else {
            diagnostics.add(MotionPathDiagnostic(path: '$path.observes[$i]', code: 'type', message: 'Must be an object.'));
          }
        }
      }
    }

    return MotionPathTrack(
      id: id is String ? id : '',
      duration: duration is num ? duration : null,
      keyframes: keyframes is Map ? Map<String, Object?>.from(keyframes) : const <String, Object?>{},
      observes: List<Map<String, Object?>>.unmodifiable(observes),
    );
  }
}
