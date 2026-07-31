import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test('supports delay and yoyo progress', () {
    const MotionPathTrigger trigger = MotionPathTrigger(
      delay: 1,
      yoyo: true,
      repeat: 1,
    );
    expect(trigger.progressAt(0.5, 1), 0);
    expect(trigger.progressAt(1.5, 1), 0.5);
    expect(trigger.progressAt(2.5, 1), 0.5);
  });

  test('reads trigger settings from authored JSON', () {
    final MotionPathTrigger trigger = MotionPathTrigger.fromJson(
      <String, Object?>{'type': 'scroll', 'scrub': true, 'autoplay': true},
    );
    expect(trigger.type, MotionPathTriggerType.scroll);
    expect(trigger.isScrub, isTrue);
    expect(trigger.autoplay, isTrue);
  });

  test('flushes dirty tracks in compiled order', () {
    final MotionPathTrackRuntime root = MotionPathTrackRuntime('root');
    final MotionPathTrackRuntime child = MotionPathTrackRuntime('child');
    final MotionPathGraphPublisher publisher = MotionPathGraphPublisher(
      <String, MotionPathTrackRuntime>{'root': root, 'child': child},
    );
    publisher.markDirty('child');
    publisher.markDirty('root');
    expect(publisher.flush(<String>['root', 'child']).keys, <String>[
      'root',
      'child',
    ]);
    expect(publisher.flush(<String>['root', 'child']), isEmpty);
  });

  test('ignores unknown dirty ids', () {
    final MotionPathGraphPublisher publisher = MotionPathGraphPublisher(
      <String, MotionPathTrackRuntime>{},
    );
    publisher.markDirty('ghost');
    expect(publisher.isDirty, isFalse);
    expect(publisher.flush(<String>['ghost']), isEmpty);
  });
}
