import 'package:motionpath_core/motionpath_core.dart';

/// The ball track is authored as v4 JSON first, matching the reference scene.
/// Runtime spawning converts this validated track into a mounted child.
const Map<String, Object?> spiralBallProjectJson = <String, Object?>{
  'schemaVersion': 4,
  'projectId': 'spiral-zuma-ball',
  'motions': <Object?>[
    <String, Object?>{
      'id': 'ball',
      'trigger': <String, Object?>{'type': 'time'},
      'tracks': <Object?>[
        <String, Object?>{
          'id': 'ball-track',
          'duration': 12.0,
          'keyframes': <String, Object?>{
            'path': <String, Object?>{
              'points': <Object?>[
                <String, Object?>{'x': 180, 'y': 30},
                <String, Object?>{'x': 320, 'y': 180},
                <String, Object?>{'x': 180, 'y': 330},
                <String, Object?>{'x': 40, 'y': 180},
                <String, Object?>{'x': 180, 'y': 30},
              ],
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': 0, 'ease': 'none'},
                <String, Object?>{'p': 1, 'v': 1, 'ease': 'none'},
              ],
            },
            'opacity': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': 0.2},
                <String, Object?>{'p': 0.05, 'v': 1},
                <String, Object?>{'p': 0.9, 'v': 1},
                <String, Object?>{'p': 1, 'v': 0},
              ],
            },
            '--ball-size': <String, Object?>{
              'stops': <Object?>[
                <String, Object?>{'p': 0, 'v': '42px'},
                <String, Object?>{'p': 1, 'v': '42px'},
              ],
            },
          },
        },
      ],
    },
  ],
};

MotionPathTrackRuntime createAuthoredSpiralBall(String id) {
  final MotionPathProject project = MotionPathProject.fromJson(
    spiralBallProjectJson,
  );
  final MotionPathTrack authored = project.motions.single.tracks.single;
  return MotionPathTrackRuntime(
    id,
    properties: propertiesFromTrack(authored),
    duration: authored.duration?.toDouble() ?? 12,
  );
}
