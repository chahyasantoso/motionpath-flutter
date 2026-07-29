import 'package:test/test.dart';
import 'package:motionpath_core/motionpath_core.dart';

void main() {
  test('supports delay and yoyo progress', () {
    final trigger = MotionPathTrigger(delay: 1, yoyo: true, repeat: 1);
    expect(trigger.progressAt(0.5, 1), 0);
    expect(trigger.progressAt(1.5, 1), 0.5);
    expect(trigger.progressAt(2.5, 1), 0.5);
  });

  test('flushes dirty tracks in compiled order', () {
    final root = MotionPathTrackRuntime('root');
    final child = MotionPathTrackRuntime('child');
    final publisher = MotionPathGraphPublisher(<String, MotionPathTrackRuntime>{'root': root, 'child': child});
    publisher.markDirty('child');
    publisher.markDirty('root');
    expect(publisher.flush(<String>['root', 'child']).keys, <String>['root', 'child']);
    expect(publisher.flush(<String>['root', 'child']), isEmpty);
  });
}
