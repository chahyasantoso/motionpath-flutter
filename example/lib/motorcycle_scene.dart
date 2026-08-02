import 'package:motionpath_core/motionpath_core.dart';

const double motorcycleRideDuration = 5;
const double motorcycleCloudDuration = 9;
const double motorcycleStreakDuration = 4.5;

const List<Map<String, Object?>> motorcycleRoadNodes = <Map<String, Object?>>[
  <String, Object?>{'x': -80, 'y': 500},
  <String, Object?>{'x': 280, 'y': 360, 'ctrlX': 60, 'ctrlY': 560},
  <String, Object?>{'x': 640, 'y': 240, 'ctrlX': 480, 'ctrlY': 180},
  <String, Object?>{'x': 960, 'y': 140, 'ctrlX': 800, 'ctrlY': 310},
  <String, Object?>{'x': 1380, 'y': 70, 'ctrlX': 1120, 'ctrlY': 30},
];

List<Map<String, Object?>> _offsetY(List<Map<String, Object?>> nodes, double offset) => <Map<String, Object?>>[
      for (final Map<String, Object?> node in nodes)
        <String, Object?>{
          ...node,
          'y': (node['y']! as num).toDouble() + offset,
          if (node.containsKey('ctrlY')) 'ctrlY': (node['ctrlY']! as num).toDouble() + offset,
        },
    ];

const List<Map<String, Object?>> motorcycleCloudANodes = <Map<String, Object?>>[
  <String, Object?>{'x': -240, 'y': 90},
  <String, Object?>{'x': 1400, 'y': 80},
];
const List<Map<String, Object?>> motorcycleCloudBNodes = <Map<String, Object?>>[
  <String, Object?>{'x': -240, 'y': 140},
  <String, Object?>{'x': 1400, 'y': 120},
];
const List<Map<String, Object?>> motorcycleStreakANodes = <Map<String, Object?>>[
  <String, Object?>{'x': -400, 'y': 510},
  <String, Object?>{'x': 1400, 'y': 510},
];
const List<Map<String, Object?>> motorcycleStreakBNodes = <Map<String, Object?>>[
  <String, Object?>{'x': -400, 'y': 470},
  <String, Object?>{'x': 1400, 'y': 470},
];

List<MotionPathStop> _pathStops(List<Map<String, Object?>> points) => <MotionPathStop>[
      MotionPathStop(progress: 0, value: <String, Object?>{'points': points, 'autoRotate': true}),
      MotionPathStop(progress: 1, value: <String, Object?>{'points': points, 'autoRotate': true}),
    ];
List<MotionPathStop> _opacity(double fadeIn, double holdEnd, double fadeOut) => <MotionPathStop>[
      const MotionPathStop(progress: 0, value: 0),
      MotionPathStop(progress: fadeIn, value: fadeIn == 0 ? 0 : 1),
      MotionPathStop(progress: holdEnd, value: 1),
      MotionPathStop(progress: fadeOut, value: 0),
      const MotionPathStop(progress: 1, value: 0),
    ];
MotionPathTrackRuntime _track(String id, List<Map<String, Object?>> points, double duration, {List<MotionPathStop>? opacity}) => MotionPathTrackRuntime(
      id,
      duration: duration,
      properties: <String, List<MotionPathStop>>{
        'path': _pathStops(points),
        if (opacity != null) 'opacity': opacity,
      },
    );

List<MotionPathTrackRuntime> motorcycleSceneTracks() => <MotionPathTrackRuntime>[
      _track('moto-bike', motorcycleRoadNodes, motorcycleRideDuration, opacity: _opacity(0.04, 0.92, 1)),
      _track('moto-shadow', _offsetY(motorcycleRoadNodes, 22), motorcycleRideDuration, opacity: _opacity(0.05, 0.92, 1)),
      _track('moto-cloud-a', motorcycleCloudANodes, motorcycleCloudDuration),
      _track('moto-cloud-b', motorcycleCloudBNodes, motorcycleCloudDuration, opacity: _opacity(0.24, 0.85, 1)),
      _track('moto-streak-a', motorcycleStreakANodes, motorcycleStreakDuration, opacity: _opacity(0.05, 0.88, 1)),
      _track('moto-streak-b', motorcycleStreakBNodes, motorcycleStreakDuration, opacity: _opacity(0.08, 0.88, 1)),
    ];
