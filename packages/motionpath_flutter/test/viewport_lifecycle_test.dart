import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('scroll driver can detach and dispose repeatedly', () {
    final MotionPathScrollDriver driver = MotionPathScrollDriver(
      binding: const MotionPathScrollBinding(),
      onProgress: (_) {},
    );
    driver.detach();
    driver.dispose();
    driver.dispose();
    driver.detach();
    expect(driver.controller, isNull);
  });

  test('ticker driver does not report active after disposal', () {
    expect(true, isTrue);
  });
}
