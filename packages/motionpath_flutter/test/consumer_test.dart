import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('reads image and CSS variable payloads', () {
    const Map<String, Object?> patch = <String, Object?>{
      'image': 'hero.png',
      'cssVariables': <String, Object?>{'--x': 12, 'color': 'drop'},
    };
    expect(MotionPathPatchConsumers.imageFrame(patch), 'hero.png');
    expect(MotionPathPatchConsumers.cssVariables(patch), <String, Object?>{
      '--x': 12,
    });
  });

  test('creates blur filter only for positive numeric values', () {
    expect(
      MotionPathPatchConsumers.blurFilter(const <String, Object?>{
        'filter': <String, Object?>{'blur': 4},
      }),
      isNotNull,
    );
    expect(
      MotionPathPatchConsumers.blurFilter(const <String, Object?>{
        'filter': <String, Object?>{'blur': 0},
      }),
      isNull,
    );
  });

  test('normalizes spawned instance records', () {
    expect(
      MotionPathPatchConsumers.instances(const <String, Object?>{
        'instances': <Object?>[
          <String, Object?>{'index': 0, 'template': 'dot'},
        ],
      }).single['template'],
      'dot',
    );
  });
}
