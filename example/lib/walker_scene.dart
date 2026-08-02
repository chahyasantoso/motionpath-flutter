import 'dart:math' as math;

import 'package:motionpath_core/motionpath_core.dart';

const double walkerHipY = 148;
const double walkerStartX = 70;
const double walkerEndX = 690;
const int walkerCycles = 4;
const int walkerSamples = 48;

const Map<String, double> walkerRig = <String, double>{
  'torso': 78,
  'neck': 26,
  'upperArm': 44,
  'forearm': 40,
  'thigh': 62,
  'shin': 56,
  'foot': 26,
};

const List<String> walkerBoneIds = <String>[
  'spine',
  'chest',
  'head',
  'arm-far-upper',
  'arm-far-fore',
  'leg-far-thigh',
  'leg-far-shin',
  'leg-far-foot',
  'arm-near-upper',
  'arm-near-fore',
  'leg-near-thigh',
  'leg-near-shin',
  'leg-near-foot',
];

const Map<String, String> walkerParents = <String, String>{
  'spine': 'pelvis',
  'chest': 'spine',
  'head': 'chest',
  'arm-far-upper': 'chest',
  'arm-far-fore': 'arm-far-upper',
  'leg-far-thigh': 'pelvis',
  'leg-far-shin': 'leg-far-thigh',
  'leg-far-foot': 'leg-far-shin',
  'arm-near-upper': 'chest',
  'arm-near-fore': 'arm-near-upper',
  'leg-near-thigh': 'pelvis',
  'leg-near-shin': 'leg-near-thigh',
  'leg-near-foot': 'leg-near-shin',
};

const Map<String, double> walkerOffsets = <String, double>{
  'spine': 0,
  'chest': 78,
  'head': 26,
  'arm-far-upper': 0,
  'arm-far-fore': 44,
  'leg-far-thigh': 0,
  'leg-far-shin': 62,
  'leg-far-foot': 56,
  'arm-near-upper': 0,
  'arm-near-fore': 44,
  'leg-near-thigh': 0,
  'leg-near-shin': 62,
  'leg-near-foot': 56,
};

double _phaseAt(double progress) => progress * walkerCycles * math.pi * 2;

List<MotionPathStop> _sample(double Function(double phase, double progress) fn) => <MotionPathStop>[
      for (int index = 0; index <= walkerSamples; index++)
        MotionPathStop(
          progress: index / walkerSamples,
          value: fn(_phaseAt(index / walkerSamples), index / walkerSamples),
        ),
    ];

List<MotionPathStop> _hold(double value) => <MotionPathStop>[
      MotionPathStop(progress: 0, value: value),
      MotionPathStop(progress: 1, value: value),
    ];

MotionPathTrackRuntime _track(
  String id,
  Map<String, List<MotionPathStop>> properties,
) => MotionPathTrackRuntime(id, properties: properties);

MotionPathTrackRuntime walkerPelvisTrack() => _track('pelvis', <String, List<MotionPathStop>>{
      'x': <MotionPathStop>[
        const MotionPathStop(progress: 0, value: walkerStartX),
        const MotionPathStop(progress: 1, value: walkerEndX),
      ],
      'y': _sample((double phase, double progress) => walkerHipY - 5 * math.sin(phase).abs()),
      'rotation': _sample((double phase, double progress) => 1.6 * math.sin(2 * phase)),
    });

List<MotionPathStop> _boneRotationStops(String id) {
  final bool far = id.contains('far');
  if (id == 'head') {
    return _sample((double phase, double progress) => -90 + 3 * math.sin(phase + 1.2));
  }
  if (id.contains('thigh')) {
    return _sample((double phase, double progress) => 90 + 26 * math.sin(phase + (far ? math.pi : 0)));
  }
  if (id.contains('shin')) {
    return _sample((double phase, double progress) => 115 + 21 * math.sin(phase + (far ? math.pi : 0) + 2.1));
  }
  if (id.contains('foot')) {
    return _sample((double phase, double progress) => -8 + 12 * math.sin(phase + (far ? math.pi : 0) + 0.9));
  }
  return _hold(-90);
}

double walkerBoneRotationAt(String id, double progress) {
  final List<MotionPathStop> stops = _boneRotationStops(id);
  return (interpolateStops(stops, progress)! as num).toDouble();
}

MotionPathTrackRuntime walkerBoneTrack(String id) {
  final String parent = walkerParents[id]!;
  final double offset = walkerOffsets[id]!;
  return _track(id, <String, List<MotionPathStop>>{
    'boneLength': _hold(offset),
    'boneRotation': _boneRotationStops(id),
    'parentWorld': _hold(parent.hashCode.toDouble()),
  });
}

List<MotionPathTrackRuntime> walkerSceneTracks() => <MotionPathTrackRuntime>[
      walkerPelvisTrack(),
      for (final String id in walkerBoneIds) walkerBoneTrack(id),
    ];
