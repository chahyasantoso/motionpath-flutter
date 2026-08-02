import 'package:motionpath_core/motionpath_core.dart';

const double burstPerspective = 800;

const List<Map<String, Object?>> burstCards = <Map<String, Object?>>[
  <String, Object?>{'id': 'strawberry-1', 'endX': -160, 'endY': -120, 'endZ': 200, 'startZ': -1420, 'end': 0.45},
  <String, Object?>{'id': 'strawberry-2', 'endX': 160, 'endY': -120, 'endZ': 150, 'startZ': -280, 'end': 0.45},
  <String, Object?>{'id': 'strawberry-3', 'endX': -40, 'endY': 140, 'endZ': 250, 'startZ': -1350, 'end': 0.6},
  <String, Object?>{'id': 'strawberry-4', 'endX': -200, 'endY': 30, 'endZ': 180, 'startZ': -1220, 'end': 0.6},
  <String, Object?>{'id': 'strawberry-5', 'endX': 200, 'endY': 60, 'endZ': 220, 'startZ': -400, 'end': 0.75},
  <String, Object?>{'id': 'strawberry-6', 'endX': -100, 'endY': -180, 'endZ': 120, 'startZ': -1310, 'end': 0.75},
  <String, Object?>{'id': 'strawberry-7', 'endX': 100, 'endY': -180, 'endZ': 240, 'startZ': -450, 'end': 0.9},
  <String, Object?>{'id': 'strawberry-8', 'endX': 80, 'endY': 160, 'endZ': 160, 'startZ': -1260, 'end': 0.9},
  <String, Object?>{'id': 'strawberry-9', 'endX': -120, 'endY': 100, 'endZ': 300, 'startZ': -370, 'end': 1.0},
  <String, Object?>{'id': 'strawberry-10', 'endX': 180, 'endY': -50, 'endZ': 100, 'startZ': -200, 'end': 1.0},
  <String, Object?>{'id': 'ice-cream-center', 'endX': 0, 'endY': -35, 'endZ': 0, 'startZ': 400, 'end': 0.7},
];

List<MotionPathStop> _hold(num value) => <MotionPathStop>[
      MotionPathStop(progress: 0, value: value),
      MotionPathStop(progress: 1, value: value),
    ];

List<MotionPathStop> _fade(double start, double peak, double end) => <MotionPathStop>[
      MotionPathStop(progress: 0, value: 0),
      MotionPathStop(progress: start, value: 0),
      MotionPathStop(progress: (start + end) / 2, value: 1),
      MotionPathStop(progress: end, value: 0),
      MotionPathStop(progress: 1, value: 0),
    ];

MotionPathTrackRuntime burstCardTrack(Map<String, Object?> card) {
  final double end = (card['end']! as num).toDouble();
  final double endX = (card['endX']! as num).toDouble();
  final double endY = (card['endY']! as num).toDouble();
  final double endZ = (card['endZ']! as num).toDouble();
  final double startZ = (card['startZ']! as num).toDouble();
  final double fadeStart = end * 0.15;
  return MotionPathTrackRuntime(
    card['id']! as String,
    properties: <String, List<MotionPathStop>>{
      'x': <MotionPathStop>[const MotionPathStop(progress: 0, value: 0), MotionPathStop(progress: end, value: endX)],
      'y': <MotionPathStop>[const MotionPathStop(progress: 0, value: 0), MotionPathStop(progress: end, value: endY)],
      'z': <MotionPathStop>[MotionPathStop(progress: 0, value: startZ), MotionPathStop(progress: end, value: endZ)],
      'opacity': _fade(fadeStart, (fadeStart + end) / 2, end),
      'perspective': _hold(burstPerspective),
    },
  );
}

List<MotionPathTrackRuntime> burstSceneTracks() => <MotionPathTrackRuntime>[
      for (final Map<String, Object?> card in burstCards) burstCardTrack(card),
    ];
