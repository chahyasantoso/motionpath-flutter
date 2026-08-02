import 'package:motionpath_core/motionpath_core.dart';

/// Authored Helix sample positions, ordered from back to front at progress 0.5.
const List<Map<String, double>> helixCardSamples = <Map<String, double>>[
  <String, double>{'x': -180, 'y': -110, 'z': -240, 'rotationY': -28, 'scale': 0.72},
  <String, double>{'x': -90, 'y': -55, 'z': -120, 'rotationY': -14, 'scale': 0.86},
  <String, double>{'x': 0, 'y': 0, 'z': 0, 'rotationY': 0, 'scale': 1},
  <String, double>{'x': 90, 'y': 55, 'z': 120, 'rotationY': 14, 'scale': 0.86},
  <String, double>{'x': 180, 'y': 110, 'z': 240, 'rotationY': 28, 'scale': 0.72},
];

const double helixPerspective = 0.0012;

MotionPathTrackRuntime helixCardTrack(
  String id, {
  required Map<String, double> sample,
}) {
  final Map<String, List<MotionPathStop>> properties = <String, List<MotionPathStop>>{};
  for (final MapEntry<String, double> entry in sample.entries) {
    properties[entry.key] = <MotionPathStop>[
      MotionPathStop(progress: 0, value: entry.value),
      MotionPathStop(progress: 1, value: entry.value),
    ];
  }
  properties['perspective'] = const <MotionPathStop>[
    MotionPathStop(progress: 0, value: helixPerspective),
    MotionPathStop(progress: 1, value: helixPerspective),
  ];
  return MotionPathTrackRuntime(id, properties: properties);
}

List<MotionPathTrackRuntime> helixSceneTracks() => <MotionPathTrackRuntime>[
      for (int index = 0; index < helixCardSamples.length; index++)
        helixCardTrack('helix-card-$index', sample: helixCardSamples[index]),
    ];
