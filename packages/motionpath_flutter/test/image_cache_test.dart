import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() {
  test('loads each frame once and evicts with explicit disposal', () {
    final MotionPathImageFrameCache<String> cache =
        MotionPathImageFrameCache<String>();
    int loads = 0;
    final String first = cache.resolve('one', (_) => 'decoded-${loads++}');
    final String second = cache.resolve('one', (_) => 'decoded-${loads++}');

    expect(first, 'decoded-0');
    expect(second, 'decoded-0');
    expect(loads, 1);
    expect(cache.length, 1);

    final List<String> disposed = <String>[];
    expect(cache.evict('one', dispose: disposed.add), isTrue);
    expect(disposed, <String>['decoded-0']);
    expect(cache.length, 0);
  });

  test('dispose releases all resources and rejects later loads', () {
    final MotionPathImageFrameCache<int> cache = MotionPathImageFrameCache<int>();
    cache.resolve('one', (_) => 1);
    cache.resolve('two', (_) => 2);
    final List<int> disposed = <int>[];

    cache.dispose(dispose: disposed.add);

    expect(disposed, <int>[1, 2]);
    expect(cache.length, 0);
    expect(
      () => cache.resolve('three', (_) => 3),
      throwsStateError,
    );
    cache.dispose(dispose: disposed.add);
    expect(disposed, <int>[1, 2]);
  });
}
