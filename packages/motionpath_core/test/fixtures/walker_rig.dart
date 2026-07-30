// Dart port of apps/demo/src/components/Walker/walkerMotions.js from the
// JavaScript reference runtime (v4.2).
//
// Only the pelvis authors a position. Every other bone authors its offset from
// its parent joint (boneLength) and its local joint angle (boneRotation), then
// declares `observes: [{ source: parent, role: input, target: parentWorld }]`.
// Angles are DOM-space degrees: +x right, +y down.
import 'dart:math' as math;

/// Bone lengths in logical pixels.
const double kTorso = 78;
const double kNeck = 26;
const double kUpperArm = 44;
const double kForearm = 40;
const double kThigh = 62;
const double kShin = 56;
const double kFoot = 26;

/// Gait cycles across the scrubbed section.
const int kCycles = 4;

/// Stops sampled per animated property.
const int kSamples = 48;

/// Pelvis travel and hip height.
const double kStartX = 70;
const double kEndX = 690;
const double kHipY = 148;

const double _tau = math.pi * 2;
const double _down = 90;
const double _up = -90;
const double _nearPhase = 0;
const double _farPhase = math.pi;

double _round(double value) => (value * 1000).round() / 1000;

double _pelvisTilt(double ph) => 1.6 * math.sin(2 * ph);
double _thighWorld(double ph) => _down + 26 * math.sin(ph);
double _kneeFlex(double ph) => 25 + 21 * math.sin(ph + 2.1);
double _shinWorld(double ph) => _thighWorld(ph) + _kneeFlex(ph);
double _footWorld(double ph) => -8 + 12 * math.sin(ph + 0.9);
double _spineWorld(double ph) => _up + 2.2 * math.sin(2 * ph);
double _chestWorld(double ph) => _spineWorld(ph) - 2 * math.sin(ph);
double _headWorld(double ph) => _up + 3 * math.sin(ph + 1.2);
double _upperArmWorld(double ph) => _down + 21 * math.sin(ph);
double _elbowFlex(double ph) => 26 + 15 * math.sin(ph + 0.7);

// World rotation accumulates down the chain, so a joint's LOCAL angle is the
// desired world angle minus the parent's world angle.
double Function(double) _hip(double shift) =>
    (double ph) => _thighWorld(ph + shift) - _pelvisTilt(ph);
double Function(double) _knee(double shift) => (double ph) => _kneeFlex(ph + shift);
double Function(double) _ankle(double shift) =>
    (double ph) => _footWorld(ph + shift) - _shinWorld(ph + shift);
double Function(double) _shoulder(double shift) =>
    (double ph) => _upperArmWorld(ph + shift) - _chestWorld(ph);
double Function(double) _elbow(double shift) => (double ph) => _elbowFlex(ph + shift);

/// Samples a phase function into JSON stops once, never per frame.
Map<String, Object?> _sample(double Function(double ph) fn) {
  final stops = <Object?>[];
  for (var i = 0; i <= kSamples; i++) {
    final double p = _round(i / kSamples);
    stops.add(<String, Object?>{'p': p, 'v': _round(fn(p * kCycles * _tau)), 'ease': 'none'});
  }
  return <String, Object?>{'stops': stops};
}

Map<String, Object?> _hold(double value) => <String, Object?>{
      'stops': <Object?>[
        <String, Object?>{'p': 0, 'v': value, 'ease': 'none'},
        <String, Object?>{'p': 1, 'v': value, 'ease': 'none'},
      ],
    };

Map<String, Object?> _bone(
  String id,
  String parent,
  Map<String, Object?> boneLength,
  Map<String, Object?> boneRotation,
) =>
    <String, Object?>{
      'id': id,
      'observes': <Object?>[
        <String, Object?>{'source': parent, 'role': 'input', 'target': 'parentWorld'},
      ],
      'keyframes': <String, Object?>{'boneLength': boneLength, 'boneRotation': boneRotation},
    };

/// The full FK walk cycle as authored v4 JSON.
Map<String, Object?> walkerProjectJson() {
  final tracks = <Object?>[
    <String, Object?>{
      'id': 'pelvis',
      'keyframes': <String, Object?>{
        'x': <String, Object?>{
          'stops': <Object?>[
            <String, Object?>{'p': 0, 'v': kStartX, 'ease': 'none'},
            <String, Object?>{'p': 1, 'v': kEndX, 'ease': 'none'},
          ],
        },
        'y': _sample((double ph) => kHipY - 5 * math.sin(ph).abs()),
        'rotation': _sample(_pelvisTilt),
      },
    },
    _bone('spine', 'pelvis', _hold(0), _sample((double ph) => _spineWorld(ph) - _pelvisTilt(ph))),
    _bone('chest', 'spine', _hold(kTorso), _sample((double ph) => _chestWorld(ph) - _spineWorld(ph))),
    _bone(
      'head',
      'chest',
      // An animated boneLength: the neck lengthens twice per cycle, which is the
      // head bob. No position is authored to make it happen.
      _sample((double ph) => kNeck + 2.5 * math.sin(2 * ph)),
      _sample((double ph) => _headWorld(ph) - _chestWorld(ph)),
    ),
    _bone('arm-far-upper', 'chest', _hold(0), _sample(_shoulder(_nearPhase))),
    _bone('arm-far-fore', 'arm-far-upper', _hold(kUpperArm), _sample(_elbow(_nearPhase))),
    _bone('leg-far-thigh', 'pelvis', _hold(0), _sample(_hip(_farPhase))),
    _bone('leg-far-shin', 'leg-far-thigh', _hold(kThigh), _sample(_knee(_farPhase))),
    _bone('leg-far-foot', 'leg-far-shin', _hold(kShin), _sample(_ankle(_farPhase))),
    _bone('arm-near-upper', 'chest', _hold(0), _sample(_shoulder(_farPhase))),
    _bone('arm-near-fore', 'arm-near-upper', _hold(kUpperArm), _sample(_elbow(_farPhase))),
    _bone('leg-near-thigh', 'pelvis', _hold(0), _sample(_hip(_nearPhase))),
    _bone('leg-near-shin', 'leg-near-thigh', _hold(kThigh), _sample(_knee(_nearPhase))),
    _bone('leg-near-foot', 'leg-near-shin', _hold(kShin), _sample(_ankle(_nearPhase))),
  ];
  return <String, Object?>{
    'schemaVersion': 4,
    'projectId': 'fk-walker',
    'motions': <Object?>[
      <String, Object?>{
        'id': 'fk-walk-cycle',
        'trigger': <String, Object?>{'type': 'scroll', 'scrub': 0.55},
        'tracks': tracks,
      },
    ],
  };
}
