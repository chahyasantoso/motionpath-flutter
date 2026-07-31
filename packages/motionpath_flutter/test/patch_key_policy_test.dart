import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('claims every generic renderer key explicitly', () {
    expect(
      motionPathUnsupportedKeys(const <String, Object?>{
        'x': 10,
        'opacity': 0.5,
        'filter': <String, Object?>{'blur': 4},
      }),
      isEmpty,
    );
  });

  test('unknown plugin keys are not falsely claimed', () {
    expect(
      motionPathUnsupportedKeys(const <String, Object?>{
        'pluginPayload': 42,
        'customRendererValue': true,
      }),
      isEmpty,
    );
  });
}
