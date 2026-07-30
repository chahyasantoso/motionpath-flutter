import 'dart:convert';

import 'package:meta/meta.dart';

import '../validation/validate_project.dart';

/// Severity of a validation diagnostic.
///
/// Mirrors the JavaScript reference runtime, where only [MotionPathSeverity.error]
/// blocks a project from loading and [MotionPathSeverity.warning] reports an
/// authoring smell that the runtime can still tolerate.
enum MotionPathSeverity {
  /// Fatal: the project must never reach the runtime.
  error,

  /// Non-fatal authoring warning.
  warning,
}

/// A single structured validation result.
@immutable
class MotionPathDiagnostic {
  /// Creates a diagnostic.
  const MotionPathDiagnostic({
    required this.path,
    required this.code,
    required this.message,
    this.severity = MotionPathSeverity.error,
  });

  /// JSON path of the offending value, for example `motions[0].trigger`.
  final String path;

  /// Stable rule identifier, matching the JavaScript `ruleId`.
  final String code;

  /// Human readable explanation.
  final String message;

  /// Whether this diagnostic blocks loading.
  final MotionPathSeverity severity;

  /// Whether this diagnostic blocks loading.
  bool get isFatal => severity == MotionPathSeverity.error;

  @override
  String toString() => '$path [$code:${severity.name}] $message';

  @override
  bool operator ==(Object other) =>
      other is MotionPathDiagnostic &&
      other.path == path &&
      other.code == code &&
      other.message == message &&
      other.severity == severity;

  @override
  int get hashCode => Object.hash(path, code, message, severity);
}

/// Thrown when a project fails validation at the trust boundary.
class MotionPathValidationException implements Exception {
  /// Creates an exception carrying every collected diagnostic.
  const MotionPathValidationException(this.diagnostics);

  /// Every diagnostic collected before failing.
  final List<MotionPathDiagnostic> diagnostics;

  @override
  String toString() {
    final String body = diagnostics
        .map((MotionPathDiagnostic diagnostic) => diagnostic.toString())
        .join('\n');
    return 'MotionPathValidationException:\n$body';
  }
}

/// Reads a decoded JSON object into a string keyed map.
///
/// Non-object values and non-string keys are dropped instead of throwing so
/// that validation can report every problem in one pass.
Map<String, Object?> asStringKeyedMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    return const <String, Object?>{};
  }
  final Map<String, Object?> result = <String, Object?>{};
  value.forEach((Object? key, Object? entry) {
    if (key is String) {
      result[key] = entry;
    }
  });
  return result;
}

/// Reads a decoded JSON array into a list of string keyed maps.
List<Map<String, Object?>> asStringKeyedMapList(Object? value) {
  if (value is! List<Object?>) {
    return const <Map<String, Object?>>[];
  }
  return <Map<String, Object?>>[
    for (final Object? entry in value) asStringKeyedMap(entry),
  ];
}

String? _optionalString(Object? value) => value is String ? value : null;

num? _optionalNum(Object? value) => value is num ? value : null;

/// A MotionPath v4 project.
class MotionPathProject {
  /// Creates a project from already validated data.
  const MotionPathProject({
    required this.schemaVersion,
    required this.projectId,
    this.perspective,
    this.templates = const <Map<String, Object?>>[],
    this.motions = const <MotionPathMotion>[],
    this.tracks = const <MotionPathTrack>[],
  });

  /// Validates and parses a decoded JSON project.
  ///
  /// This is the trust boundary: every fatal diagnostic is collected first and
  /// thrown together as a single [MotionPathValidationException].
  factory MotionPathProject.fromJson(Map<String, Object?> json) {
    final List<MotionPathDiagnostic> fatal = validateProject(json)
        .where((MotionPathDiagnostic diagnostic) => diagnostic.isFatal)
        .toList(growable: false);
    if (fatal.isNotEmpty) {
      throw MotionPathValidationException(
        List<MotionPathDiagnostic>.unmodifiable(fatal),
      );
    }
    final List<Map<String, Object?>> templates =
        asStringKeyedMapList(json['templates']);
    return MotionPathProject(
      schemaVersion: 4,
      projectId: _optionalString(json['projectId']),
      perspective: _optionalNum(json['perspective']),
      templates: List<Map<String, Object?>>.unmodifiable(templates),
      motions: List<MotionPathMotion>.unmodifiable(<MotionPathMotion>[
        for (final Map<String, Object?> motion
            in asStringKeyedMapList(json['motions']))
          MotionPathMotion.fromJson(motion, templates: templates),
      ]),
      tracks: List<MotionPathTrack>.unmodifiable(<MotionPathTrack>[
        for (final Map<String, Object?> track
            in asStringKeyedMapList(json['tracks']))
          MotionPathTrack.fromJson(track, templates: templates),
      ]),
    );
  }

  /// Validates and parses a JSON source string.
  factory MotionPathProject.fromJsonString(String source) =>
      MotionPathProject.fromJson(asStringKeyedMap(jsonDecode(source)));

  /// Only schema version 4 is supported.
  final int schemaVersion;

  /// Optional authored project identifier.
  final String? projectId;

  /// Optional perspective used by 3D aware renderers.
  final num? perspective;

  /// Raw track templates, still JSON shaped.
  final List<Map<String, Object?>> templates;

  /// Motions declared by the project.
  final List<MotionPathMotion> motions;

  /// Standalone tracks declared outside any motion.
  final List<MotionPathTrack> tracks;

  /// Finds a motion by authored id.
  MotionPathMotion? motionById(String id) {
    for (final MotionPathMotion motion in motions) {
      if (motion.id == id) {
        return motion;
      }
    }
    return null;
  }
}

/// One motion: a single trigger and the tracks that share it.
class MotionPathMotion {
  /// Creates a motion.
  const MotionPathMotion({
    required this.id,
    required this.trigger,
    this.stagger = 0,
    this.tracks = const <MotionPathTrack>[],
  });

  /// Reads a motion from validated JSON, resolving track templates.
  factory MotionPathMotion.fromJson(
    Map<String, Object?> json, {
    List<Map<String, Object?>> templates = const <Map<String, Object?>>[],
  }) {
    return MotionPathMotion(
      id: _optionalString(json['id']) ?? '',
      trigger: asStringKeyedMap(json['trigger']),
      stagger: _optionalNum(json['stagger'])?.toDouble() ?? 0,
      tracks: <MotionPathTrack>[
        for (final Map<String, Object?> track
            in asStringKeyedMapList(json['tracks']))
          MotionPathTrack.fromJson(track, templates: templates),
      ],
    );
  }

  /// Authoritative motion id. `motionId` is a forbidden v3 field.
  final String id;

  /// Raw trigger data, interpreted by the runtime trigger.
  final Map<String, Object?> trigger;

  /// Stagger between child tracks, in seconds.
  final double stagger;

  /// Tracks owned by this motion.
  final List<MotionPathTrack> tracks;
}

/// One track: a normalized playhead plus authored keyframes and observations.
class MotionPathTrack {
  /// Creates a track.
  const MotionPathTrack({
    required this.id,
    this.use,
    this.duration,
    this.keyframes = const <String, Object?>{},
    this.observes = const <Map<String, Object?>>[],
  });

  /// Reads a track from validated JSON, merging its template when present.
  factory MotionPathTrack.fromJson(
    Map<String, Object?> json, {
    List<Map<String, Object?>> templates = const <Map<String, Object?>>[],
  }) {
    final String? use = _optionalString(json['use']);
    Map<String, Object?> template = const <String, Object?>{};
    if (use != null) {
      for (final Map<String, Object?> candidate in templates) {
        if (_optionalString(candidate['templateId']) == use) {
          template = candidate;
          break;
        }
      }
    }
    final Map<String, Object?> keyframes = <String, Object?>{
      ...asStringKeyedMap(template['keyframes']),
      ...asStringKeyedMap(json['keyframes']),
    };
    final List<Map<String, Object?>> observes = json.containsKey('observes')
        ? asStringKeyedMapList(json['observes'])
        : asStringKeyedMapList(template['observes']);
    return MotionPathTrack(
      id: _optionalString(json['id']) ?? '',
      use: use,
      duration:
          _optionalNum(json['duration']) ?? _optionalNum(template['duration']),
      keyframes: Map<String, Object?>.unmodifiable(keyframes),
      observes: List<Map<String, Object?>>.unmodifiable(observes),
    );
  }

  /// Track id, unique within its motion.
  final String id;

  /// Optional template id this track stamps from.
  final String? use;

  /// Track duration in seconds. Forbidden on scroll-scrub motions.
  final num? duration;

  /// Authored keyframes, keyed by property name.
  final Map<String, Object?> keyframes;

  /// Declarative observation edges.
  final List<Map<String, Object?>> observes;
}
