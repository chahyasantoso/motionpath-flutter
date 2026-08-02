import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

const List<Object?> _points = <Object?>[
  <String, Object?>{'x': -100, 'y': 50},
  <String, Object?>{'x': 0, 'y': 0, 'ctrlX': -20, 'ctrlY': 80},
  <String, Object?>{'x': 100, 'y': 50, 'ctrlX': 80, 'ctrlY': -30},
];

MotionPathTrackRuntime _card() => MotionPathTrackRuntime(
      'carousel-card',
      properties: <String, List<MotionPathStop>>{
        'path': <MotionPathStop>[
          MotionPathStop(
            progress: 0,
            value: <String, Object?>{
              'points': _points,
              'autoRotate': true,
              'anchor': 'center',
            },
          ),
          MotionPathStop(
            progress: 1,
            value: <String, Object?>{
              'points': _points,
              'autoRotate': true,
              'anchor': 'center',
            },
          ),
        ],
        'opacity': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0),
          MotionPathStop(progress: 0.15, value: 1),
          MotionPathStop(progress: 0.85, value: 1),
          MotionPathStop(progress: 1, value: 0),
        ],
        'scale': const <MotionPathStop>[
          MotionPathStop(progress: 0, value: 0.8),
          MotionPathStop(progress: 0.15, value: 1),
          MotionPathStop(progress: 0.85, value: 1),
          MotionPathStop(progress: 1, value: 0.8),
        ],
      },
    );

void main() {
  test('Carousel path, opacity, scale, and rotation come from composed patches', () {
    final MotionPathTrackRuntime track = _card();
    for (final double progress in <double>[0, 0.15, 0.5, 0.85, 1]) {
      track.seek(progress);
      final Map<String, Object?> patch = track.compose();
      expect(patch.containsKey('path'), isFalse);
      expect(patch['opacity'], isA<num>());
      expect(patch['scale'], isA<num>());
      expect(patch['rotation'], isA<num>());
      expect(patch['x'], isA<num>());
      expect(patch['y'], isA<num>());
      expect(patch['anchorXPercent'], 50);
      expect(patch['anchorYPercent'], 50);
      expect(patch['opacity'], progress == 0 || progress == 1 ? 0 : 1);
      expect(patch['scale'], progress == 0 || progress == 1 ? 0.8 : 1);
    }
  });

  test('Carousel geometry is deterministic at the same progress', () {
    final MotionPathTrackRuntime first = _card();
    final MotionPathTrackRuntime second = _card();
    for (final double progress in <double>[0, 0.15, 0.5, 0.85, 1]) {
      first.seek(progress);
      second.seek(progress);
      expect(second.compose(), first.compose());
    }
  });
}
