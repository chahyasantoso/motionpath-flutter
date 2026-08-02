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
