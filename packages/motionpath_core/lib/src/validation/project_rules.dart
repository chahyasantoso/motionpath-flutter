import '../contract/motionpath_types.dart';
import '../graph/observation_graph.dart';

/// Rule `schema-version`: only schema version 4 is supported.
List<MotionPathDiagnostic> schemaVersionRule(Map<String, Object?> json) {
  final Object? version = json['schemaVersion'];
  if (version is! int) {
    return const <MotionPathDiagnostic>[
      MotionPathDiagnostic(
        path: r'$.schemaVersion',
        code: 'schema-version',
        message: 'schemaVersion is required and must be the integer 4.',
      ),
    ];
  }
  if (version != 4) {
    return <MotionPathDiagnostic>[
      MotionPathDiagnostic(
        path: r'$.schemaVersion',
        code: 'schema-version',
        message: 'Only schema version 4 is supported. Got: $version.',
      ),
    ];
  }
  return const <MotionPathDiagnostic>[];
}

/// Rule `perspective-usage`: perspective must be numeric when present.
List<MotionPathDiagnostic> perspectiveUsageRule(Map<String, Object?> json) {
  final Object? perspective = json['perspective'];
  if (perspective == null || perspective is num) {
    return const <MotionPathDiagnostic>[];
  }
  return const <MotionPathDiagnostic>[
    MotionPathDiagnostic(
      path: r'$.perspective',
      code: 'perspective-usage',
      message: 'perspective must be numeric.',
    ),
  ];
}

/// Rule `motion-structure`: templates, motion identity, and forbidden v3 fields.
List<MotionPathDiagnostic> motionStructureRule(Map<String, Object?> json) {
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  final Set<String> templateIds = <String>{};
  final List<Map<String, Object?>> templates =
      asStringKeyedMapList(json['templates']);

  for (int index = 0; index < templates.length; index++) {
    final Map<String, Object?> template = templates[index];
    final String path = 'templates[$index]';
    final Object? templateId = template['templateId'];
    if (templateId is! String || templateId.isEmpty) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$path.templateId',
        code: 'motion-structure',
        message: 'templateId is required and must be a string.',
      ));
    } else if (!templateIds.add(templateId)) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$path.templateId',
        code: 'motion-structure',
        message: "Duplicate templateId '$templateId' found.",
      ));
    }
    for (final String forbidden in const <String>[
      'driver',
      'timelineId',
      'primary',
      'trigger',
    ]) {
      if (template.containsKey(forbidden)) {
        diagnostics.add(MotionPathDiagnostic(
          path: '$path.$forbidden',
          code: 'motion-structure',
          message: 'Template forbids $forbidden property.',
        ));
      }
    }
  }

  final Set<String> motionIds = <String>{};
  final List<Map<String, Object?>> motions =
      asStringKeyedMapList(json['motions']);
  for (int index = 0; index < motions.length; index++) {
    final Map<String, Object?> motion = motions[index];
    final String path = 'motions[$index]';
    if (motion.containsKey('motionId')) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$path.motionId',
        code: 'motion-structure',
        message:
            '"motionId" is a v3 field, not valid in v4 -- rename it to "id".',
      ));
    }
    final Object? id = motion['id'];
    if (id is! String || id.isEmpty) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$path.id',
        code: 'motion-structure',
        message: 'motion.id is required and must be a non-empty string.',
      ));
    } else if (!motionIds.add(id)) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$path.id',
        code: 'motion-structure',
        message: "Duplicate motion id '$id' found.",
      ));
    }
    for (final String forbidden in const <String>[
      'driver',
      'timelineId',
      'primary',
      'lifecycle',
      'playback',
    ]) {
      if (motion.containsKey(forbidden)) {
        diagnostics.add(MotionPathDiagnostic(
          path: '$path.$forbidden',
          code: 'motion-structure',
          message: '"$forbidden" is a v2/v3 field, not valid in v4.',
        ));
      }
    }
    final Object? trigger = motion['trigger'];
    if (trigger == null) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$path.trigger',
        code: 'motion-structure',
        message: 'trigger is required on every motion in v4.',
      ));
    } else if (trigger is! Map<Object?, Object?>) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$path.trigger',
        code: 'motion-structure',
        message: 'trigger must be an object.',
      ));
    } else {
      final Object? type = asStringKeyedMap(trigger)['type'];
      if (type is! String || type.isEmpty) {
        diagnostics.add(MotionPathDiagnostic(
          path: '$path.trigger.type',
          code: 'motion-structure',
          message: 'trigger.type is required and must be a string.',
        ));
      }
    }
    diagnostics.addAll(_tracksArrayRule(
      motion['tracks'],
      '$path.tracks',
      id is String && id.isNotEmpty ? id : '$index',
      templateIds,
    ));
  }

  if (json.containsKey('tracks')) {
    diagnostics.addAll(
      _tracksArrayRule(json['tracks'], 'tracks', 'top-level', templateIds),
    );
  }
  return diagnostics;
}

List<MotionPathDiagnostic> _tracksArrayRule(
  Object? tracks,
  String path,
  String owner,
  Set<String> templateIds,
) {
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  if (tracks == null) {
    diagnostics.add(MotionPathDiagnostic(
      path: path,
      code: 'motion-structure',
      message: 'Motion "$owner": tracks must have at least 1 entry.',
    ));
    return diagnostics;
  }
  if (tracks is! List<Object?>) {
    diagnostics.add(MotionPathDiagnostic(
      path: path,
      code: 'motion-structure',
      message: 'tracks must be an array.',
    ));
    return diagnostics;
  }
  if (tracks.isEmpty) {
    diagnostics.add(MotionPathDiagnostic(
      path: path,
      code: 'motion-structure',
      message: 'Motion "$owner": tracks must have at least 1 entry.',
    ));
    return diagnostics;
  }
  for (int index = 0; index < tracks.length; index++) {
    final Map<String, Object?> track = asStringKeyedMap(tracks[index]);
    if (track.isEmpty) {
      continue;
    }
    final Object? id = track['id'];
    if (id is! String || id.isEmpty) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$path[$index].id',
        code: 'motion-structure',
        message:
            'Motion "$owner": track.id is required and must be a non-empty string.',
      ));
    }
    final Object? use = track['use'];
    if (use != null && (use is! String || !templateIds.contains(use))) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$path[$index].use',
        code: 'motion-structure',
        message: "Track references non-existent templateId '$use'.",
      ));
    }
  }
  return diagnostics;
}

/// Rule `trigger-shape`: per-motion trigger validation.
List<MotionPathDiagnostic> triggerShapeRule(
  Map<String, Object?> motion,
  String path,
) {
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  final String triggerPath = '$path.trigger';
  final Object? rawTrigger = motion['trigger'];
  if (rawTrigger == null) {
    diagnostics.add(MotionPathDiagnostic(
      path: triggerPath,
      code: 'trigger-shape',
      message: 'motion trigger is required.',
    ));
    return diagnostics;
  }
  if (rawTrigger is! Map<Object?, Object?>) {
    diagnostics.add(MotionPathDiagnostic(
      path: triggerPath,
      code: 'trigger-shape',
      message: 'motion trigger must be an object.',
    ));
    return diagnostics;
  }
  final Map<String, Object?> trigger = asStringKeyedMap(rawTrigger);
  final Object? type = trigger['type'];
  if (type is! String || type.isEmpty) {
    diagnostics.add(MotionPathDiagnostic(
      path: '$triggerPath.type',
      code: 'trigger-shape',
      message: 'trigger.type is required.',
    ));
    return diagnostics;
  }
  if (type != 'time' && type != 'manual' && type != 'scroll') {
    diagnostics.add(MotionPathDiagnostic(
      path: '$triggerPath.type',
      code: 'trigger-shape',
      message:
          "trigger.type must be 'scroll', 'time', or 'manual'. Got: \"$type\".",
    ));
    return diagnostics;
  }
  if (type == 'manual') {
    return diagnostics;
  }

  final Object? scrub = trigger['scrub'];
  if (type == 'scroll') {
    if (scrub == null) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$triggerPath.scrub',
        code: 'trigger-shape',
        message: "scroll trigger requires 'scrub' parameter.",
      ));
    } else if (scrub is! bool && scrub is! num) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$triggerPath.scrub',
        code: 'trigger-shape',
        message:
            "scroll trigger 'scrub' parameter must be a boolean or a number.",
      ));
    }
  }

  final bool isScrub = type == 'scroll' && (scrub == true || scrub is num);
  if (trigger['endTrigger'] != null && !isScrub) {
    diagnostics.add(MotionPathDiagnostic(
      path: '$triggerPath.endTrigger',
      code: 'trigger-shape',
      message: 'endTrigger is only valid on scroll triggers with scrub:true.',
    ));
  }
  final bool hasRepeatSettings = trigger['repeat'] != null ||
      trigger['yoyo'] != null ||
      trigger['repeatDelay'] != null;
  if (isScrub && hasRepeatSettings) {
    diagnostics.add(MotionPathDiagnostic(
      path: triggerPath,
      code: 'trigger-shape',
      message:
          'repeat, yoyo, and repeatDelay are incompatible with scroll-scrub triggers.',
    ));
  }
  if (isScrub && trigger['delay'] != null) {
    diagnostics.add(MotionPathDiagnostic(
      path: '$triggerPath.delay',
      code: 'trigger-shape',
      message: 'delay is incompatible with scroll-scrub triggers.',
    ));
  }
  if (isScrub) {
    final Object? tracks = motion['tracks'];
    if (tracks is List<Object?>) {
      for (int index = 0; index < tracks.length; index++) {
        final Map<String, Object?> track = asStringKeyedMap(tracks[index]);
        if (track['duration'] == null) {
          continue;
        }
        final Object? trackId = track['id'];
        final String label = trackId is String && trackId.isNotEmpty
            ? trackId
            : 'unknown';
        diagnostics.add(MotionPathDiagnostic(
          path: '$path.tracks[$index].duration',
          code: 'trigger-shape',
          message:
              "duration is incompatible with scroll-scrub triggers (found on track '$label').",
        ));
      }
    }
  }
  return diagnostics;
}

/// Rules `stop-count`, `stop-shape`, and `stop-sequence` for one track.
List<MotionPathDiagnostic> trackKeyframeRules(
  Map<String, Object?> track,
  String path,
) {
  final List<MotionPathDiagnostic> diagnostics = <MotionPathDiagnostic>[];
  final Map<String, Object?> keyframes = asStringKeyedMap(track['keyframes']);
  if (keyframes.isEmpty) {
    return diagnostics;
  }
  final Object? rawId = track['id'];
  final String label = rawId is String && rawId.isNotEmpty ? rawId : 'unknown';

  for (final MapEntry<String, Object?> entry in keyframes.entries) {
    final String propertyPath = '$path.keyframes.${entry.key}';
    final Map<String, Object?> config = asStringKeyedMap(entry.value);
    if (config.isEmpty) {
      continue;
    }
    final Object? rawStops = config['stops'];
    final List<Object?> stops =
        rawStops is List<Object?> ? rawStops : const <Object?>[];
    if (stops.length < 2) {
      diagnostics.add(MotionPathDiagnostic(
        path: propertyPath,
        code: 'stop-count',
        message:
            "Property '${entry.key}' on track '$label' must have at least 2 stops, but got ${stops.length}.",
      ));
    }

    double previous = double.negativeInfinity;
    final Set<num> seen = <num>{};
    bool hasZero = false;
    bool hasOne = false;
    for (int index = 0; index < stops.length; index++) {
      final String stopPath = '$propertyPath.stops[$index]';
      final Object? raw = stops[index];
      if (raw is! Map<Object?, Object?>) {
        diagnostics.add(MotionPathDiagnostic(
          path: stopPath,
          code: 'stop-shape',
          message:
              "Stop at index $index for property '${entry.key}' on track '$label' must be a plain object.",
        ));
        continue;
      }
      final Map<String, Object?> stop = asStringKeyedMap(raw);
      final Object? progress = stop['p'];
      if (progress == null) {
        diagnostics.add(MotionPathDiagnostic(
          path: '$stopPath.p',
          code: 'stop-shape',
          message:
              "Stop at index $index for property '${entry.key}' on track '$label' is missing required property 'p'.",
        ));
      } else if (progress is! num || progress < 0 || progress > 1) {
        diagnostics.add(MotionPathDiagnostic(
          path: '$stopPath.p',
          code: 'stop-shape',
          message:
              "Stop at index $index for property '${entry.key}' on track '$label' must have 'p' as a number between 0 and 1.",
        ));
      } else {
        if (!seen.add(progress)) {
          diagnostics.add(MotionPathDiagnostic(
            path: '$stopPath.p',
            code: 'stop-sequence',
            message:
                'Duplicate stop position $progress for property "${entry.key}".',
          ));
        }
        if (progress.toDouble() < previous) {
          diagnostics.add(MotionPathDiagnostic(
            path: '$stopPath.p',
            code: 'stop-sequence',
            message:
                'Stop positions for property "${entry.key}" must be monotonic.',
          ));
        }
        previous = progress.toDouble();
        if (progress == 0) {
          hasZero = true;
        }
        if (progress == 1) {
          hasOne = true;
        }
      }
      if (stop['v'] == null) {
        diagnostics.add(MotionPathDiagnostic(
          path: '$stopPath.v',
          code: 'stop-shape',
          message:
              "Stop at index $index for property '${entry.key}' on track '$label' must have a defined 'v' value.",
        ));
      }
    }
    if (!hasZero) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$propertyPath.stops',
        code: 'stop-sequence',
        severity: MotionPathSeverity.warning,
        message:
            'Property "${entry.key}" has no p: 0 stop; its first frame may be undefined.',
      ));
    }
    if (!hasOne) {
      diagnostics.add(MotionPathDiagnostic(
        path: '$propertyPath.stops',
        code: 'stop-sequence',
        severity: MotionPathSeverity.warning,
        message: 'Property "${entry.key}" has no p: 1 stop.',
      ));
    }
  }
  return diagnostics;
}

/// Rule `track-observations`: compiles the graph IR and reports its errors.
List<MotionPathDiagnostic> trackObservationsRule(
  MotionPathMotion motion,
  String path,
) {
  final ObservationGraph graph = normalizeObservationGraph(motion);
  return <MotionPathDiagnostic>[
    for (final MotionPathDiagnostic error in graph.errors)
      MotionPathDiagnostic(
        path: '$path.${error.path}',
        code: error.code,
        message: error.message,
        severity: error.severity,
      ),
  ];
}
