import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

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
) =>
    <String, Object?>{
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

MotionPathProject _rig() => MotionPathProject.fromJson(<String, Object?>{
      'schemaVersion': 4,
      'projectId': 'walker',
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
  test('compiles the rig parent-before-child', () {
    final MotionPathEngine engine = MotionPathEngine()..loadProject(_rig());
    final MotionPathMotionRuntime motion = engine.mountMotion('rig');
    expect(motion.graphOrder, <String>['pelvis', 'thigh', 'shin']);
    engine.destroy();
  });

  test('holds the FK invariant at every sampled progress', () {
    final MotionPathEngine engine = MotionPathEngine()..loadProject(_rig());
    final MotionPathMotionRuntime motion = engine.mountMotion('rig');
    for (final double progress in <double>[0, 0.25, 0.5, 0.75, 1]) {
      motion.seek(progress);
      final Map<String, Map<String, Object?>> patches = motion.composeGraph();
      expect(
        patchDistance(patches['pelvis']!, patches['thigh']!),
        closeTo(70, 1e-9),
      );
      expect(
        patchDistance(patches['thigh']!, patches['shin']!),
        closeTo(56, 1e-9),
      );
    }
    engine.destroy();
  });

  test('accumulates world rotation down the chain', () {
    final MotionPathEngine engine = MotionPathEngine()..loadProject(_rig());
    final MotionPathMotionRuntime motion = engine.mountMotion('rig');
    motion.seek(1);
    final Map<String, Map<String, Object?>> patches = motion.composeGraph();
    expect(patches['pelvis']!['rotation'], closeTo(45, 1e-9));
    expect(patches['thigh']!['rotation'], closeTo(85, 1e-9));
    expect(patches['shin']!['rotation'], closeTo(120, 1e-9));
    engine.destroy();
  });

  test('resolves a diamond from one shared parent', () {
    final MotionPathProject project =
        MotionPathProject.fromJson(<String, Object?>{
      'schemaVersion': 4,
      'motions': <Object?>[
        <String, Object?>{
          'id': 'diamond',
          'trigger': <String, Object?>{'type': 'manual'},
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'root',
              'duration': 1,
              'keyframes': <String, Object?>{
                'x': _ramp(0, 10),
                'y': _hold(0),
                'rotation': _hold(0),
              },
            },
            _bone('left', 'root', 30, 0, 0),
            _bone('right', 'root', 40, 0, 0),
          ],
        },
      ],
    });
    final MotionPathEngine engine = MotionPathEngine()..loadProject(project);
    final MotionPathMotionRuntime motion = engine.mountMotion('diamond');
    motion.seek(1);
    final Map<String, Map<String, Object?>> patches = motion.composeGraph();
    expect(patches['left']!['x'], closeTo(40, 1e-9));
    expect(patches['right']!['x'], closeTo(50, 1e-9));
    engine.destroy();
  });

  test('rejects an output collision on one track', () {
    final MotionPathProject project =
        MotionPathProject.fromJson(<String, Object?>{
      'schemaVersion': 4,
      'motions': <Object?>[
        <String, Object?>{
          'id': 'collide',
          'trigger': <String, Object?>{'type': 'manual'},
          'tracks': <Object?>[
            <String, Object?>{
              'id': 'elbow',
              'duration': 1,
              'keyframes': <String, Object?>{
                'boneLength': _hold(10),
                'rotation': _ramp(0, 90),
              },
            },
          ],
        },
      ],
    });
    final MotionPathEngine engine = MotionPathEngine()..loadProject(project);
    expect(() => engine.mountMotion('collide'), throwsStateError);
    engine.destroy();
  });
}
