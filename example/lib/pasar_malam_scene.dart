import 'package:motionpath_core/motionpath_core.dart';

const double pasarMalamPerspective = 800;
const double pasarMalamBounceDuration = 1.2;
const int pasarMalamFrameCount = 192;

final List<String> pasarMalamImageFrames = List<String>.unmodifiable(
  List<String>.generate(
    pasarMalamFrameCount,
    (int index) => '/sequence/frame_${(index + 1).toString().padLeft(4, '0')}.webp',
  ),
);

List<MotionPathStop> _stops(List<Object?> values) => <MotionPathStop>[
      for (int index = 0; index < values.length; index++)
        MotionPathStop(
          progress: index / (values.length - 1),
          value: values[index],
        ),
    ];

MotionPathTrackRuntime _track(
  String id,
  Map<String, List<MotionPathStop>> properties,
) => MotionPathTrackRuntime(id, properties: properties);

List<MotionPathTrackRuntime> pasarMalamStoryTracks() => <MotionPathTrackRuntime>[
      _track('pasar-malam-bg', <String, List<MotionPathStop>>{
        'imageSequence': _stops(<Object?>[pasarMalamImageFrames]),
      }),
      _track('hero-title', <String, List<MotionPathStop>>{
        'opacity': _stops(<Object?>[0, 1, 1, 0]),
        'y': _stops(<Object?>[120, 0, 0, -120]),
        'scaleX': _stops(<Object?>[1.25, 1, 1, 0.8]),
        'scaleY': _stops(<Object?>[1.25, 1, 1, 0.8]),
      }),
      _track('card-left', <String, List<MotionPathStop>>{
        'x': _stops(<Object?>[-720, 0, 0, -720]),
        'rotation': _stops(<Object?>[-8, 0, 0, -8]),
        'opacity': _stops(<Object?>[0, 1, 1, 0]),
      }),
      _track('card-right', <String, List<MotionPathStop>>{
        'x': _stops(<Object?>[720, 0, 0, 720]),
        'rotation': _stops(<Object?>[8, 0, 0, 8]),
        'opacity': _stops(<Object?>[0, 1, 1, 0]),
      }),
      _track('stats-card', <String, List<MotionPathStop>>{
        'y': _stops(<Object?>[160, 0, 0, 160]),
        'opacity': _stops(<Object?>[0, 1, 1, 0]),
        'neonOpacity': _stops(<Object?>[1, 1, 0.1, 1, 1, 0.3, 1, 1, 0.15, 1]),
      }),
      _track('lantern-1-wrap', <String, List<MotionPathStop>>{
        'y': _stops(<Object?>[-120, 0, 0]),
        'opacity': _stops(<Object?>[0, 1, 1]),
      }),
      _track('lantern-2-wrap', <String, List<MotionPathStop>>{
        'y': _stops(<Object?>[-150, 0, 0]),
        'opacity': _stops(<Object?>[0, 1, 1]),
      }),
      _track('lantern-3-wrap', <String, List<MotionPathStop>>{
        'y': _stops(<Object?>[-100, 0, 0]),
        'opacity': _stops(<Object?>[0, 1, 1]),
      }),
    ];

List<MotionPathTrackRuntime> pasarMalamBounceTracks() => <MotionPathTrackRuntime>[
      for (final Map<String, Object?> config in <Map<String, Object?>>[
        <String, Object?>{'id': 'lantern-1', 'y': -18},
        <String, Object?>{'id': 'lantern-2', 'y': -12},
        <String, Object?>{'id': 'lantern-3', 'y': -20},
      ])
        MotionPathTrackRuntime(
          config['id']! as String,
          duration: pasarMalamBounceDuration,
          properties: <String, List<MotionPathStop>>{
            'y': <MotionPathStop>[
              const MotionPathStop(progress: 0, value: 0),
              MotionPathStop(progress: 1, value: config['y']),
            ],
          },
        ),
    ];
