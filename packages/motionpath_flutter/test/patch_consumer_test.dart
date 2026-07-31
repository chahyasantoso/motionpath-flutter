import 'dart:ui' show ImageFilter;

import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('rejects invalid blur sigma values', () {
    for (final Object? value in <Object?>[-1, double.nan, double.infinity]) {
      expect(
        MotionPathPatchConsumers.blurFilter(<String, Object?>{
          'filter': <String, Object?>{'blur': value},
        }),
        isNull,
      );
    }
  });

  test('clamps excessive blur sigma values', () {
    final ImageFilter? filter = MotionPathPatchConsumers.blurFilter(
      <String, Object?>{
        'filter': <String, Object?>{'blur': kMotionPathMaxBlurSigma * 4},
      },
    );
    expect(filter, isNotNull);
  });

  test('ignores unknown payload keys by contract', () {
    expect(
      MotionPathPatchConsumers.cssVariables(<String, Object?>{
        'cssVariables': <String, Object?>{
          '--tone': 2,
          'not-css': 3,
        },
      }),
      <String, Object?>{'--tone': 2},
    );
  });
}
