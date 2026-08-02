import 'dart:ui' show Path;

import 'package:motionpath_core/motionpath_core.dart';

const List<Object?> carouselPathPoints = <Object?>[
  <String, Object?>{'x': -260, 'y': 310},
  <String, Object?>{
    'x': 200,
    'y': 130,
    'ctrlX': -20,
    'ctrlY': 70,
  },
  <String, Object?>{
    'x': 660,
    'y': 360,
    'ctrlX': 520,
    'ctrlY': 180,
  },
  <String, Object?>{
    'x': 1120,
    'y': 150,
    'ctrlX': 900,
    'ctrlY': 560,
  },
  <String, Object?>{
    'x': 1520,
    'y': 300,
    'ctrlX': 1320,
    'ctrlY': -80,
  },
];

Map<String, Object?> carouselPathPayload() => <String, Object?>{
      'points': carouselPathPoints,
      'autoRotate': true,
    };

List<MotionPathStop> _pathStops() => <MotionPathStop>[
      MotionPathStop(progress: 0, value: carouselPathPayload()),
      MotionPathStop(progress: 1, value: carouselPathPayload()),
    ];

List<MotionPathStop> _opacityStops() => const <MotionPathStop>[
      MotionPathStop(progress: 0, value: 0),
      MotionPathStop(progress: 0.15, value: 1),
      MotionPathStop(progress: 0.85, value: 1),
      MotionPathStop(progress: 1, value: 0),
    ];

MotionPathTrackRuntime carouselCardTrack(String id) => MotionPathTrackRuntime(
      id,
      properties: <String, List<MotionPathStop>>{
        'path': _pathStops(),
        'opacity': _opacityStops(),
      },
    );

const double carouselCardStagger = 0.1;

/// The stage guide drawn behind the cards.
///
/// Built from [carouselPathPoints] with the same quadratic control semantics
/// the engine samples, so the painted guide cannot drift from the authored
/// scene. Demo chrome reads the scene; it never restates it.
Path carouselGuidePath() {
  final Path path = Path();
  final Map<String, Object?> start =
      carouselPathPoints.first! as Map<String, Object?>;
  path.moveTo(
    (start['x']! as num).toDouble(),
    (start['y']! as num).toDouble(),
  );
  for (final Object? raw in carouselPathPoints.skip(1)) {
    final Map<String, Object?> point = raw! as Map<String, Object?>;
    final double x = (point['x']! as num).toDouble();
    final double y = (point['y']! as num).toDouble();
    final num? ctrlX = point['ctrlX'] as num?;
    final num? ctrlY = point['ctrlY'] as num?;
    if (ctrlX == null || ctrlY == null) {
      path.lineTo(x, y);
    } else {
      path.quadraticBezierTo(ctrlX.toDouble(), ctrlY.toDouble(), x, y);
    }
  }
  return path;
}
