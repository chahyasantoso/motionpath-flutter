import 'package:motionpath_core/motionpath_core.dart';

const List<Map<String, Object?>> hooksRocketPoints = <Map<String, Object?>>[
  <String, Object?>{'x': 50, 'y': 300},
  <String, Object?>{'x': 400, 'y': 100, 'ctrlX': 200, 'ctrlY': -50},
  <String, Object?>{'x': 900, 'y': 350, 'ctrlX': 700, 'ctrlY': 500},
];
const List<Map<String, Object?>> hooksCloudPoints = <Map<String, Object?>>[
  <String, Object?>{'x': -100, 'y': 80},
  <String, Object?>{'x': 1100, 'y': 80},
];
const double hooksDemoPerspective = 1200;
List<MotionPathStop> _path(List<Map<String, Object?>> points) => <MotionPathStop>[
  MotionPathStop(progress: 0, value: <String, Object?>{'points': points, 'autoRotate': true}),
  MotionPathStop(progress: 1, value: <String, Object?>{'points': points, 'autoRotate': true}),
];
List<MotionPathTrackRuntime> hooksDemoSceneTracks() => <MotionPathTrackRuntime>[
  MotionPathTrackRuntime('rocket-track', properties: <String, List<MotionPathStop>>{
    'path': _path(hooksRocketPoints), 'scale': <MotionPathStop>[const MotionPathStop(progress: 0, value: 0.8), const MotionPathStop(progress: 1, value: 1.3)], 'opacity': <MotionPathStop>[const MotionPathStop(progress: 0, value: 0.4), const MotionPathStop(progress: 1, value: 1)],
  }),
  MotionPathTrackRuntime('cloud', properties: <String, List<MotionPathStop>>{'path': _path(hooksCloudPoints)}),
];
