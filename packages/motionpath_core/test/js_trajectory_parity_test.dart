import 'dart:convert';
import 'dart:io';

import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

// Whole-timeline trajectory parity against the JS v4 renderer contract.
//
// `js_parity_fixture_test.dart` samples five progress points per case, which
// is enough to catch a wrong curve but not enough to catch drift in
// arc-length pacing, colour channel rounding, frame-index boundaries, or the
// moment a key leaves the patch. These cases sample nine points across a full
// normalized timeline and assert every one, so a regression fails at the
// sample where it starts instead of averaging out.

Map<String, Object?> _fixture() {
  final File file = File('test/fixtures/motionpath_trajectory_fixtures.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

double _number(Object? value) => (value! as num).toDouble();

List<Map<String, Object?>> _samples(Map<String, Object?> cases, String name) {
  final Map<String, Object?> entry = cases[name]! as Map<String, Object?>;
  final List<Object?> raw = entry['samples']! as List<Object?>;
  return <Map<String, Object?>>[
    for (final Object? sample in raw) sample! as Map<String, Object?>,
  ];
}

Map<String, Object?> _patch(Map<String, Object?> sample) =>
    sample['patch']! as Map<String, Object?>;

/// Parses the CSS colour forms the JS reference emits.
///
/// This deliberately does not reuse the core parser. The expected side of a
/// parity assertion must never be produced by the code under test.
int _argbFromCss(String css) {
  if (css.startsWith('#')) {
    return 0xFF000000 | int.parse(css.substring(1), radix: 16);
  }
  final int open = css.indexOf('(');
  final int close = css.indexOf(')');
  final List<String> parts = css.substring(open + 1, close).split(',');
  final int alpha = (double.parse(parts[3]) * 255).round();
  return (alpha << 24) |
      (int.parse(parts[0].trim()) << 16) |
      (int.parse(parts[1].trim()) << 8) |
      int.parse(parts[2].trim());
}

String _frameFromCssUrl(String css) =>
    css.replaceFirst('url(', '').replaceFirst(')', '');

// Three axis-aligned segments of exactly 100 units each: x, then y, then z.
// A straight cubic with evenly spaced control points is exactly linear in t,
// so every expected sample position is closed form rather than approximated.
const Map<String, Object?> _cardPath = <String, Object?>{
  'points': <Map<String, Object?>>[
    <String, Object?>{'x': 0, 'y': 0, 'z': 0},
    <String, Object?>{'x': 100, 'y': 0, 'z': 0},
    <String, Object?>{'x': 100, 'y': 100, 'z': 0},
    <String, Object?>{'x': 100, 'y': 100, 'z': 100},
  ],
};

const List<String> _spriteFrames = <String>[
  'frame-0.png',
  'frame-1.png',
  'frame-2.png',
  'frame-3.png',
];

const Map<String, Object?> _badgeOverlay = <String, Object?>{'label': 'intro'};

// Every track resolves its plugins through the default registry, so these
// cases also prove the registry wires path, image sequence, overlay, and the
// property passthrough the way a real host would get them.
MotionPathTrackRuntime _cardTrack() {
  return MotionPathTrackRuntime(
    'card',
    properties: const <String, List<MotionPathStop>>{
      'path': <MotionPathStop>[MotionPathStop(progress: 0, value: _cardPath)],
      'opacity': <MotionPathStop>[
        MotionPathStop(progress: 0, value: 0),
        MotionPathStop(progress: 1, value: 1),
      ],
      'scale': <MotionPathStop>[
        MotionPathStop(progress: 0, value: 1),
        MotionPathStop(progress: 1, value: 2),
      ],
      'color': <MotionPathStop>[
        MotionPathStop(progress: 0, value: 0xFF000000),
        MotionPathStop(progress: 1, value: 0xFFFFFFFF),
      ],
    },
  );
}

// Depth and 3D rotation are authored properties rather than plugin output, so
// this track also proves `z` survives normalization as renderer metadata
// instead of being dropped with the internal keys.
MotionPathTrackRuntime _rotationTrack() {
  return MotionPathTrackRuntime(
    'rotation3d',
    properties: const <String, List<MotionPathStop>>{
      'rotation': <MotionPathStop>[
        MotionPathStop(progress: 0, value: 0),
        MotionPathStop(progress: 1, value: 180),
      ],
      'rotationX': <MotionPathStop>[
        MotionPathStop(progress: 0, value: 0),
        MotionPathStop(progress: 1, value: 90),
      ],
      'rotationY': <MotionPathStop>[
        MotionPathStop(progress: 0, value: -45),
        MotionPathStop(progress: 1, value: 45),
      ],
      'z': <MotionPathStop>[
        MotionPathStop(progress: 0, value: -100),
        MotionPathStop(progress: 1, value: 100),
      ],
    },
  );
}

MotionPathTrackRuntime _spriteTrack() {
  return MotionPathTrackRuntime(
    'sprite',
    properties: const <String, List<MotionPathStop>>{
      'imageSequence': <MotionPathStop>[
        MotionPathStop(progress: 0, value: _spriteFrames),
      ],
    },
  );
}

MotionPathTrackRuntime _badgeTrack() {
  return MotionPathTrackRuntime(
    'badge',
    properties: const <String, List<MotionPathStop>>{
      'overlay': <MotionPathStop>[
        MotionPathStop(progress: 0, value: _badgeOverlay),
        MotionPathStop(progress: 0.5, value: null),
      ],
      'opacity': <MotionPathStop>[
        MotionPathStop(progress: 0, value: 0),
        MotionPathStop(progress: 1, value: 1),
      ],
    },
  );
}

Map<String, Object?> _hold(num value) => <String, Object?>{
  'stops': <Object?>[
    <String, Object?>{'p': 0, 'v': value},
    <String, Object?>{'p': 1, 'v': value},
  ],
};

Map<String, Object?> _ramp(num from, num to) => <String, Object?>{
  'stops': <Object?>[
    <String, Object?>{'p': 0, 'v': from},
    <String, Object?>{'p': 1, 'v': to},
  ],
};

Map<String, Object?> _bone(
  String id,
  String parent,
  num length,
  num from,
  num to,
) => <String, Object?>{
  'id': id,
  'duration': 1,
  'observes': <Object?>[
    <String, Object?>{
      'source': parent,
      'role': 'input',
      'target': 'parentWorld',
    },
  ],
  'keyframes': <String, Object?>{
    'boneLength': _hold(length),
    'boneRotation': _ramp(from, to),
  },
};

// A three-bone chain driven through the engine rather than through hand-wired
// runtimes, so the case also covers project parsing, graph ordering, and input
// observation wiring on the way to the sampled world transforms.
MotionPathProject _rigProject() => MotionPathProject.fromJson(<String, Object?>{
  'schemaVersion': 4,
  'projectId': 'trajectory-rig',
  'motions': <Object?>[
    <String, Object?>{
      'id': 'rig',
      'trigger': <String, Object?>{'type': 'manual'},
      'tracks': <Object?>[
        <String, Object?>{
          'id': 'pelvis',
          'duration': 1,
          'keyframes': <String, Object?>{
            'x': _ramp(0, 120),
            'y': _ramp(0, -20),
            'rotation': _ramp(0, 45),
          },
        },
        _bone('thigh', 'pelvis', 70, 10, 40),
        _bone('shin', 'thigh', 56, 20, 35),
      ],
    },
  ],
});

void main() {
  final Map<String, Object?> fixture = _fixture();
  final Map<String, Object?> cases = fixture['cases']! as Map<String, Object?>;
  final double tolerance = _number(fixture['tolerance']);

  test('card trajectory matches JS transforms, depth, and colour', () {
    final MotionPathTrackRuntime track = _cardTrack();
    final List<Map<String, Object?>> rows = _samples(cases, 'card');
    expect(rows, isNotEmpty);
    for (final Map<String, Object?> row in rows) {
      final double progress = _number(row['progress']);
      final Map<String, Object?> expected = _patch(row);
      track.seek(progress);
      final Map<String, Object?> actual = track.compose();
      expect(
        actual.keys.toSet(),
        expected.keys.toSet(),
        reason: 'patch keys at progress $progress',
      );
      for (final String key in <String>['x', 'y', 'z', 'opacity', 'scale']) {
        expect(
          _number(actual[key]),
          closeTo(_number(expected[key]), tolerance),
          reason: '$key at progress $progress',
        );
      }
      expect(
        actual['color'],
        _argbFromCss(expected['color']! as String),
        reason: 'colour at progress $progress',
      );
    }
  });

  test('rotation trajectory keeps 3D rotation and depth metadata', () {
    final MotionPathTrackRuntime track = _rotationTrack();
    final List<Map<String, Object?>> rows = _samples(cases, 'rotation3d');
    expect(rows, isNotEmpty);
    for (final Map<String, Object?> row in rows) {
      final double progress = _number(row['progress']);
      final Map<String, Object?> expected = _patch(row);
      track.seek(progress);
      final Map<String, Object?> actual = track.compose();
      expect(
        actual.keys.toSet(),
        expected.keys.toSet(),
        reason: 'patch keys at progress $progress',
      );
      for (final String key in expected.keys) {
        expect(
          _number(actual[key]),
          closeTo(_number(expected[key]), tolerance),
          reason: '$key at progress $progress',
        );
      }
    }
  });

  test('rig trajectory matches JS forward kinematics world transforms', () {
    final MotionPathEngine engine = MotionPathEngine()
      ..loadProject(_rigProject());
    final MotionPathMotionRuntime motion = engine.mountMotion('rig');
    final List<Map<String, Object?>> rows = _samples(cases, 'rig');
    expect(rows, isNotEmpty);
    for (final Map<String, Object?> row in rows) {
      final double progress = _number(row['progress']);
      final Map<String, Object?> expected =
          row['patches']! as Map<String, Object?>;
      motion.seek(progress);
      final Map<String, Map<String, Object?>> actual = motion.composeGraph();
      expect(
        actual.keys.toSet(),
        expected.keys.toSet(),
        reason: 'graph tracks at progress $progress',
      );
      for (final String id in expected.keys) {
        final Map<String, Object?> bone = expected[id]! as Map<String, Object?>;
        expect(
          actual[id]!.keys.toSet(),
          bone.keys.toSet(),
          reason: 'patch keys for $id at progress $progress',
        );
        for (final String key in bone.keys) {
          expect(
            _number(actual[id]![key]),
            closeTo(_number(bone[key]), tolerance),
            reason: '$id $key at progress $progress',
          );
        }
      }
    }
    engine.destroy();
  });

  test('sprite trajectory selects the same JS frame at every sample', () {
    final MotionPathTrackRuntime track = _spriteTrack();
    final List<Map<String, Object?>> rows = _samples(cases, 'sprite');
    expect(rows, isNotEmpty);
    for (final Map<String, Object?> row in rows) {
      final double progress = _number(row['progress']);
      final Map<String, Object?> expected = _patch(row);
      track.seek(progress);
      final Map<String, Object?> actual = track.compose();
      expect(
        actual['image'],
        _frameFromCssUrl(expected['image']! as String),
        reason: 'frame at progress $progress',
      );
    }
  });

  test('badge trajectory drops overlay without disturbing other keys', () {
    final MotionPathTrackRuntime track = _badgeTrack();
    final List<Map<String, Object?>> rows = _samples(cases, 'badge');
    expect(rows, isNotEmpty);
    for (final Map<String, Object?> row in rows) {
      final double progress = _number(row['progress']);
      final Map<String, Object?> expected = _patch(row);
      track.seek(progress);
      final Map<String, Object?> actual = track.compose();
      expect(
        actual.keys.toSet(),
        expected.keys.toSet(),
        reason: 'patch keys at progress $progress',
      );
      final Object? expectedOverlay = expected['overlay'];
      if (expectedOverlay != null) {
        expect(
          actual['overlay'],
          expectedOverlay,
          reason: 'overlay payload at progress $progress',
        );
      }
      expect(
        _number(actual['opacity']),
        closeTo(_number(expected['opacity']), tolerance),
        reason: 'opacity at progress $progress',
      );
    }
  });
}
