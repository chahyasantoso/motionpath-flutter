import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

MotionPathTrackRuntime _track(
  String id, {
  MotionPathLayoutDelegate? layoutDelegate,
}) => MotionPathTrackRuntime(id, layoutDelegate: layoutDelegate);

void main() {
  test('children are placed one stagger after the frontmost sibling', () {
    final MotionPathTrackRuntime parent = _track('parent');
    final List<double> spawned = <double>[];
    parent.onChildSpawned = (MotionPathTrackRuntime child, double offset) =>
        spawned.add(offset);

    parent.addChild(_track('a'), stagger: 4);
    parent.addChild(_track('b'), stagger: 4);
    parent.addChild(_track('c'), stagger: 4);

    expect(spawned, <double>[0, 4, 8]);
    expect(parent.childCount, 3);
    expect(parent.getChild('b')?.currentOffset, 4);
    expect(parent.getChild('b')?.staggerOffset, 4);
    expect(parent.getChild('b')?.parent, same(parent));
  });

  test('a mid-chain removal closes the gap and reports every move', () {
    final MotionPathTrackRuntime parent = _track('parent');
    final Map<String, double> reflowed = <String, double>{};
    parent.onChildReflowed = (MotionPathTrackRuntime child, double offset) =>
        reflowed[child.id] = offset;

    for (final String id in <String>['a', 'b', 'c', 'd']) {
      parent.addChild(_track(id), stagger: 10);
    }
    parent.removeChild('b');

    expect(reflowed, <String, double>{'c': 10, 'd': 20});
    expect(parent.getChild('a')?.currentOffset, 0);
    expect(parent.getChild('c')?.currentOffset, 10);
    expect(parent.getChild('d')?.currentOffset, 20);
    expect(parent.childCount, 3);
  });

  test('removing the frontmost child leaves survivors where they were', () {
    final MotionPathTrackRuntime parent = _track('parent');
    for (final String id in <String>['a', 'b', 'c']) {
      parent.addChild(_track(id), stagger: 10);
    }
    final MotionPathTrackRuntime detached = parent.getChild('a')!;

    parent.removeChild('a');

    expect(detached.parent, isNull);
    expect(parent.getChild('b')?.currentOffset, 10);
    expect(parent.getChild('c')?.currentOffset, 20);
  });

  test('the static policy leaves the gap open and keeps growing the span', () {
    final MotionPathTrackRuntime parent = _track(
      'parent',
      layoutDelegate: kStaticLayoutDelegate,
    );
    for (final String id in <String>['a', 'b', 'c']) {
      parent.addChild(_track(id), stagger: 10);
    }

    parent.removeChild('b');
    expect(parent.getChild('c')?.currentOffset, 20);

    parent.addChild(_track('d'), stagger: 10);
    expect(parent.getChild('d')?.currentOffset, 30);
  });

  test('removing an unknown child is a no-op', () {
    final MotionPathTrackRuntime parent = _track('parent');
    parent.onChildRemoved = (MotionPathTrackRuntime child) =>
        fail('nothing was removed');
    parent.addChild(_track('a'));

    parent.removeChild('missing');

    expect(parent.childCount, 1);
  });

  test('re-parenting and duplicate ids fail early', () {
    final MotionPathTrackRuntime first = _track('first');
    final MotionPathTrackRuntime second = _track('second');
    final MotionPathTrackRuntime child = _track('child');

    first.addChild(child);

    expect(() => second.addChild(child), throwsStateError);
    expect(() => first.addChild(_track('child')), throwsStateError);
  });

  test('a detached child can be re-parented', () {
    final MotionPathTrackRuntime first = _track('first');
    final MotionPathTrackRuntime second = _track('second');
    final MotionPathTrackRuntime child = _track('child');

    first.addChild(child, stagger: 3);
    first.removeChild('child');
    second.addChild(child, stagger: 7);

    expect(child.parent, same(second));
    expect(child.currentOffset, 0);
    expect(child.staggerOffset, 7);
  });

  test('disposal cascades, is idempotent, and closes the chain', () {
    final MotionPathTrackRuntime parent = _track('parent');
    final MotionPathTrackRuntime child = _track('child');
    final MotionPathTrackRuntime grandchild = _track('grandchild');
    parent.addChild(child);
    child.addChild(grandchild);

    parent.dispose();
    parent.dispose();

    expect(parent.isDisposed, isTrue);
    expect(child.isDisposed, isTrue);
    expect(grandchild.isDisposed, isTrue);
    expect(parent.childCount, 0);
    expect(child.parent, isNull);
    expect(() => parent.addChild(_track('late')), throwsStateError);
  });

  test('composition never advances a child playhead on its own', () {
    final MotionPathTrackRuntime parent = _track('parent');
    final MotionPathTrackRuntime child = _track('child');
    parent.addChild(child, stagger: 5);

    parent.seek(1);

    expect(child.progress, 0);
  });
}
