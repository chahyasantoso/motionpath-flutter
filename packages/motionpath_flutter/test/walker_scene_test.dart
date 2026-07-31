import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

Map<String, Object?> _project() => <String, Object?>{
  'schemaVersion': 4,
  'projectId': 'walker-scene',
  'motions': <Object?>[
    <String, Object?>{
      'id': 'rig',
      'trigger': <String, Object?>{'type': 'manual'},
      'tracks': <Object?>[
        <String, Object?>{
          'id': 'pelvis',
          'keyframes': <String, Object?>{
            'x': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': 70, 'ease': 'none'},
                <String, Object?>{'p': 1, 'v': 690, 'ease': 'none'},
              ],
            },
            'y': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': 148, 'ease': 'none'},
                <String, Object?>{'p': 1, 'v': 148, 'ease': 'none'},
              ],
            },
            'rotation': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': 0, 'ease': 'none'},
                <String, Object?>{'p': 1, 'v': 0, 'ease': 'none'},
              ],
            },
          },
        },
        <String, Object?>{
          'id': 'spine',
          'observes': <Object?>[
            <String, Object?>{
              'source': 'pelvis',
              'role': 'input',
              'target': 'parentWorld',
            },
          ],
          'keyframes': <String, Object?>{
            'boneLength': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': 0, 'ease': 'none'},
                <String, Object?>{'p': 1, 'v': 0, 'ease': 'none'},
              ],
            },
            'boneRotation': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': -90, 'ease': 'none'},
                <String, Object?>{'p': 1, 'v': -90, 'ease': 'none'},
              ],
            },
          },
        },
      ],
    },
  ],
};

void main() {
  group('renderer boundary units', () {
    test('reads patch rotation as authored degrees', () {
      final MotionPathPatchTransform transform =
          MotionPathPatchTransform.fromPatch(const <String, Object?>{
            'rotation': 180,
          });
      expect(transform.rotation, 180);
      expect(transform.rotationRadians, closeTo(math.pi, 1e-9));
    });

    test('builds a rotation matrix from degrees, not radians', () {
      final List<double> storage = const MotionPathPatchTransform(
        rotation: 90,
      ).toMatrix4Storage().toList();
      expect(storage[0], closeTo(0, 1e-9));
      expect(storage[1], closeTo(1, 1e-9));
      expect(storage[4], closeTo(-1, 1e-9));
      expect(storage[5], closeTo(0, 1e-9));
    });
  });

  group('walker segments', () {
    test('aims a bone along its composed world rotation', () {
      final List<MotionPathWalkerSegment> segments = resolveWalkerSegments(
        <String, Map<String, Object?>>{
          'spine': <String, Object?>{'x': 100.0, 'y': 148.0, 'rotation': -90.0},
        },
        bones: const <MotionPathWalkerBone>[
          MotionPathWalkerBone(
            id: 'spine',
            drawLength: 78,
            tone: MotionPathWalkerTone.core,
          ),
        ],
      );
      expect(segments.length, 1);
      expect(segments.single.origin.dx, closeTo(100, 1e-9));
      expect(segments.single.tip.dx, closeTo(100, 1e-9));
      // -90 degrees points UP in DOM space, so the tip sits above the joint.
      expect(segments.single.tip.dy, closeTo(70, 1e-9));
      expect(segments.single.length, closeTo(78, 1e-9));
    });

    test('skips pure joints and missing patches', () {
      final List<MotionPathWalkerSegment> segments = resolveWalkerSegments(
        <String, Map<String, Object?>>{
          'chest': <String, Object?>{'x': 0.0, 'y': 0.0},
        },
      );
      expect(segments, isEmpty);
    });

    test('paints every drawn bone of the default rig once', () {
      final Map<String, Map<String, Object?>> patches =
          <String, Map<String, Object?>>{
            for (final MotionPathWalkerBone bone in kMotionPathWalkerBones)
              bone.id: <String, Object?>{'x': 10.0, 'y': 20.0, 'rotation': 0.0},
          };
      final List<MotionPathWalkerSegment> segments = resolveWalkerSegments(
        patches,
      );
      expect(segments.length, 11);
      for (final MotionPathWalkerSegment segment in segments) {
        expect(segment.length, closeTo(segment.bone.drawLength, 1e-9));
      }
    });
  });

  group('walker scene', () {
    testWidgets('an engine tick drives the rig without a rebuild', (
      WidgetTester tester,
    ) async {
      final MotionPathEngine engine = MotionPathEngine()
        ..loadProject(MotionPathProject.fromJson(_project()));
      final MotionPathMotionRuntime motion = engine.mountMotion('rig')..play();
      final MotionPathPatchSource source = MotionPathPatchSource()
        ..bind(motion);
      await tester.pumpWidget(
        Center(
          child: MotionPathWalkerScene(
            source: source,
            size: const Size(760, 300),
          ),
        ),
      );
      engine.tick(0.5);
      await tester.pump();
      final Map<String, Object?> spine = source.patchFor('spine');
      expect((spine['x']! as num).toDouble(), closeTo(380, 1e-9));
      expect((spine['rotation']! as num).toDouble(), closeTo(-90, 1e-9));
      expect(tester.takeException(), isNull);
      engine.destroy();
    });

    testWidgets('paints an empty source without throwing', (
      WidgetTester tester,
    ) async {
      final MotionPathPatchSource source = MotionPathPatchSource();
      await tester.pumpWidget(
        Center(child: MotionPathWalkerScene(source: source)),
      );
      expect(tester.takeException(), isNull);
    });

    test('repaints only when the rig description changes', () {
      final MotionPathPatchSource source = MotionPathPatchSource();
      final MotionPathWalkerPainter painter = MotionPathWalkerPainter(
        source: source,
      );
      expect(
        painter.shouldRepaint(MotionPathWalkerPainter(source: source)),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          MotionPathWalkerPainter(
            source: source,
            joints: const <MotionPathWalkerJoint>[],
          ),
        ),
        isTrue,
      );
    });
  });
}
