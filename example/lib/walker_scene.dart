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
  'spine', 'chest', 'head', 'arm-far-upper', 'arm-far-fore',
  'leg-far-thigh', 'leg-far-shin', 'leg-far-foot', 'arm-near-upper',
  'arm-near-fore', 'leg-near-thigh', 'leg-near-shin', 'leg-near-foot',
];

const Map<String, String> walkerParents = <String, String>{
  'spine': 'pelvis', 'chest': 'spine', 'head': 'chest',
  'arm-far-upper': 'chest', 'arm-far-fore': 'arm-far-upper',
  'leg-far-thigh': 'pelvis', 'leg-far-shin': 'leg-far-thigh',
  'leg-far-foot': 'leg-far-shin', 'arm-near-upper': 'chest',
  'arm-near-fore': 'arm-near-upper', 'leg-near-thigh': 'pelvis',
  'leg-near-shin': 'leg-near-thigh', 'leg-near-foot': 'leg-near-shin',
};

const Map<String, double> walkerOffsets = <String, double>{
  'spine': 0, 'chest': 78, 'head': 26, 'arm-far-upper': 0,
  'arm-far-fore': 44, 'leg-far-thigh': 0, 'leg-far-shin': 62,
  'leg-far-foot': 56, 'arm-near-upper': 0, 'arm-near-fore': 44,
  'leg-near-thigh': 0, 'leg-near-shin': 62, 'leg-near-foot': 56,
};

double _phase(double progress) => progress * walkerCycles * math.pi * 2;
double _pelvisTilt(double phase) => 1.6 * math.sin(2 * phase);
double _thighWorld(double phase) => 90 + 26 * math.sin(phase);
double _kneeFlex(double phase) => 25 + 21 * math.sin(phase + 2.1);
double _shinWorld(double phase) => _thighWorld(phase) + _kneeFlex(phase);
double _footWorld(double phase) => -8 + 12 * math.sin(phase + 0.9);
double _spineWorld(double phase) => -90 + 2.2 * math.sin(2 * phase);
double _chestWorld(double phase) => _spineWorld(phase) - 2 * math.sin(phase);
double _headWorld(double phase) => -90 + 3 * math.sin(phase + 1.2);
double _upperArmWorld(double phase) => 90 + 21 * math.sin(phase);
double _elbowFlex(double phase) => 26 + 15 * math.sin(phase + 0.7);

List<Map<String, Object?>> _stops(double Function(double phase, double p) fn) => <Map<String, Object?>>[
      for (int i = 0; i <= walkerSamples; i++) <String, Object?>{
        'p': i / walkerSamples,
        'v': fn(_phase(i / walkerSamples), i / walkerSamples),
        'ease': 'none',
      },
    ];

Map<String, Object?> _hold(double value) => <String, Object?>{
      'stops': <Object?>[
        <String, Object?>{'p': 0, 'v': value, 'ease': 'none'},
        <String, Object?>{'p': 1, 'v': value, 'ease': 'none'},
      ],
    };

Map<String, Object?> _sample(double Function(double phase, double p) fn) => <String, Object?>{'stops': _stops(fn)};

Map<String, Object?> _bone(String id) {
  final String parent = walkerParents[id]!;
  final bool far = id.contains('far');
  double rotation(double phase) {
    if (id == 'spine') return _spineWorld(phase) - _pelvisTilt(phase);
    if (id == 'chest') return _chestWorld(phase) - _spineWorld(phase);
    if (id == 'head') return _headWorld(phase) - _chestWorld(phase);
    final double shifted = phase + (far ? math.pi : 0);
    if (id.contains('thigh')) return _thighWorld(shifted) - _pelvisTilt(phase);
    if (id.contains('shin')) return _kneeFlex(shifted);
    if (id.contains('foot')) return _footWorld(shifted) - _shinWorld(shifted);
    if (id.contains('upper')) return _upperArmWorld(shifted) - _chestWorld(phase);
    if (id.contains('fore')) return _elbowFlex(shifted);
    return -90;
  }
  final Object length = id == 'head'
      ? _sample((double phase, double p) => walkerRig['neck']! + 2.5 * math.sin(2 * phase))
      : _hold(walkerOffsets[id]!);
  return <String, Object?>{
    'id': id,
    'observes': <Object?>[
      <String, Object?>{'source': parent, 'role': 'input', 'target': 'parentWorld'},
    ],
    'keyframes': <String, Object?>{
      'boneLength': length,
      'boneRotation': _sample((double phase, double p) => rotation(phase)),
    },
  };
}

Map<String, Object?> walkerProjectJson() => <String, Object?>{
      'schemaVersion': 4,
      'projectId': 'fk-walker',
      'motions': <Object?>[
        <String, Object?>{
          'id': 'fk-walk-cycle',
          'trigger': <String, Object?>{'type': 'scroll', 'scrub': 0.55},
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'pelvis',
              'keyframes': <String, Object?>{
                'x': <String, Object?>{
                  'stops': <Object?>[
                    <String, Object?>{'p': 0, 'v': walkerStartX, 'ease': 'none'},
                    <String, Object?>{'p': 1, 'v': walkerEndX, 'ease': 'none'},
                  ],
                },
                'y': _sample((double phase, double p) => walkerHipY - 5 * math.sin(phase).abs()),
                'rotation': _sample((double phase, double p) => _pelvisTilt(phase)),
              },
            },
            for (final String id in walkerBoneIds) _bone(id),
          ],
        },
      ],
    };

MotionPathProject walkerProject() => MotionPathProject.fromJson(walkerProjectJson());

MotionPathMotionRuntime walkerMotionRuntime() {
  final MotionPathEngine engine = MotionPathEngine()..loadProject(walkerProject());
  return engine.mountMotion('fk-walk-cycle');
}

double walkerBoneRotationAt(String id, double progress) {
  final Map<String, Object?> track = _bone(id);
  final Map<String, Object?> keyframes = track['keyframes']! as Map<String, Object?>;
  final List<MotionPathStop> stops = stopsFromKeyframe(keyframes['boneRotation']);
  return (interpolateStops(stops, progress)! as num).toDouble();
}
