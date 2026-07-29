import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('constructs the Flutter adapter boundary', () {
    expect(const MotionPathFlutterAdapter(), isNotNull);
  });
}
