import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

const List<Object?> _carouselPoints = <Object?>[
  <String, Object?>{'x': -260, 'y': 310},
  <String, Object?>{'x': 200, 'y': 130, 'ctrlX': -20, 'ctrlY': 70},
  <String, Object?>{'x': 660, 'y': 360, 'ctrlX': 520, 'ctrlY': 180},
  <String, Object?>{'x': 1120, 'y': 150, 'ctrlX': 900, 'ctrlY': 560},
  <String, Object?>{'x': 1520, 'y': 300, 'ctrlX': 1320, 'ctrlY': -80},
];

Map<String, Object?> _path() => <String, Object?>{
      'points': _carouselPoints,
      'autoRotate': true,
      'stops': <Object?>[
        <String, Object?>{'p': 0, 'v': 0},
        <String, Object?>{'p': 1, 'v': 1},
      ],
    };

MotionPathTrackRuntime _card(String id) => MotionPathTrackRuntime(
      id,
      properties: <String, List<MotionPathStop>>{
        'path': <MotionPathStop>[
          MotionPathStop(progress: 0, value: _path()),
          MotionPathStop(progress: 1, value: _path()),
        ],
        'opacity': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 0.15, value: 1),
          MotionPathStop(progress: 0.85, value: 1),
          MotionPathStop(progress: 1, value: 0),
        ],
      },
    );

void main() {
  test('shared Carousel scene keeps the JS-authored path and transition contract', () {
    final MotionPathTrackRuntime track = _card('carousel-card');
    for (final double progress in <double>[0, 0.15, 0.5, 0.85, 1]) {
      track.seek(progress);
      final Map<String, Object?> patch = track.compose();
      expect(patch.containsKey('path'), isFalse);
      expect(patch['x'], isA<num>());
      expect(patch['y'], isA<num>());
      expect(patch['rotation'], isA<num>());
      expect(patch['opacity'], progress == 0 || progress == 1 ? 0 : 1);
    }
  });

  test('Carousel stagger remains a controller concern, not scene math', () {
    final MotionPathSpawnController controller = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('carousel-parent'),
      childDuration: 1,
    );
    controller.spawn(_card('card-a'), stagger: 0.1);
    controller.spawn(_card('card-b'), stagger: 0.1);
    controller.advanceTo(0.1);
    expect(controller.instances[0].progress, closeTo(0.1, 1e-9));
    expect(controller.instances[1].progress, 0);
    controller.dispose();
  });
}
