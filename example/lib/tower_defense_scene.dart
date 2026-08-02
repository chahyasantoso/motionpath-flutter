import 'package:motionpath_core/motionpath_core.dart';

const double towerDefensePerspective = 1200;
const List<Map<String, Object?>> towerDefenseLane1Points = <Map<String, Object?>>[
  <String, Object?>{'x': 0, 'y': 150},
  <String, Object?>{'x': 220, 'y': 80, 'ctrlX': 110, 'ctrlY': 30},
  <String, Object?>{'x': 450, 'y': 380, 'ctrlX': 320, 'ctrlY': 420},
  <String, Object?>{'x': 680, 'y': 120, 'ctrlX': 580, 'ctrlY': 100},
  <String, Object?>{'x': 900, 'y': 200, 'ctrlX': 800, 'ctrlY': 280},
];
const List<Map<String, Object?>> towerDefenseLane2Points = <Map<String, Object?>>[
  <String, Object?>{'x': 0, 'y': 350},
  <String, Object?>{'x': 220, 'y': 420, 'ctrlX': 110, 'ctrlY': 470},
  <String, Object?>{'x': 450, 'y': 120, 'ctrlX': 320, 'ctrlY': 80},
  <String, Object?>{'x': 680, 'y': 380, 'ctrlX': 580, 'ctrlY': 400},
  <String, Object?>{'x': 900, 'y': 300, 'ctrlX': 800, 'ctrlY': 220},
];

List<MotionPathStop> _stops(List<Object?> values) => <MotionPathStop>[
  for (int i = 0; i < values.length; i++) MotionPathStop(progress: i / (values.length - 1), value: values[i]),
];
List<MotionPathStop> _line(num a, num b) => <MotionPathStop>[MotionPathStop(progress: 0, value: a), MotionPathStop(progress: 1, value: b)];
MotionPathTrackRuntime towerDefensePathTrack(String id, List<Map<String, Object?>> points) => MotionPathTrackRuntime(id, properties: <String, List<MotionPathStop>>{'path': _stops(<Object?>[<String, Object?>{'points': points, 'autoRotate': true}, <String, Object?>{'points': points, 'autoRotate': true}])});

List<MotionPathTrackRuntime> towerDefenseSceneTracks() => <MotionPathTrackRuntime>[
  towerDefensePathTrack('lane-1-track', towerDefenseLane1Points),
  towerDefensePathTrack('lane-2-track', towerDefenseLane2Points),
  MotionPathTrackRuntime('tower-pulse-ring', duration: 1.6, properties: <String, List<MotionPathStop>>{
    'scale': _stops(<Object?>[0.5, 1.8, 0.5]), 'opacity': _stops(<Object?>[0.6, 0, 0.6]),
  }),
  MotionPathTrackRuntime('projectile-track', duration: 1, properties: <String, List<MotionPathStop>>{
    'scale': _stops(<Object?>[0.5, 1.3, 0.7]), 'opacity': _stops(<Object?>[1, 1, 0]),
  }),
  MotionPathTrackRuntime('death-track', duration: 1, properties: <String, List<MotionPathStop>>{
    'rotation': _line(0, 270), 'scale': _stops(<Object?>[1, 1.4, 0]), 'opacity': _line(1, 0),
  }),
];
