import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

class _Child implements MotionPathLayoutChild {
  _Child(this.currentOffset);

  @override
  double currentOffset;
}

void main() {
  group('gapless spawn placement', () {
    test('an empty chain resolves to zero', () {
      expect(
        kGaplessLayoutDelegate.computeSpawnOffset(
          const <MotionPathLayoutChild>[],
          stagger: 5,
        ),
        0,
      );
    });

    test('a single child appends one stagger after it', () {
      expect(
        kGaplessLayoutDelegate.computeSpawnOffset(<MotionPathLayoutChild>[
          _Child(10),
        ], stagger: 5),
        15,
      );
    });

    test(
      'placement anchors to the frontmost offset, not the last inserted',
      () {
        expect(
          kGaplessLayoutDelegate.computeSpawnOffset(<MotionPathLayoutChild>[
            _Child(10),
            _Child(25),
            _Child(15),
          ], stagger: 5),
          30,
        );
      },
    );

    test('a zero stagger stacks a new child on the frontmost offset', () {
      expect(
        kGaplessLayoutDelegate.computeSpawnOffset(<MotionPathLayoutChild>[
          _Child(10),
        ]),
        10,
      );
    });
  });

  group('gapless reflow', () {
    test('removing the frontmost child never reflows', () {
      final List<MotionPathLayoutChild> children = <MotionPathLayoutChild>[
        _Child(0),
        _Child(10),
        _Child(20),
      ];
      expect(
        kGaplessLayoutDelegate.computeReflow(children, children.first),
        isEmpty,
      );
    });

    test(
      'a mid-chain removal cascades survivors down one slot, in rank order',
      () {
        final _Child first = _Child(0);
        final _Child second = _Child(10);
        final _Child third = _Child(20);
        final _Child fourth = _Child(30);
        // Passed out of insertion order on purpose: the policy must order by
        // settled offset itself.
        final List<MotionPathLayoutChild> children = <MotionPathLayoutChild>[
          third,
          first,
          fourth,
          second,
        ];

        expect(
          kGaplessLayoutDelegate.computeReflow(children, second),
          <MotionPathReflowTarget>[
            MotionPathReflowTarget(child: third, offset: 10),
            MotionPathReflowTarget(child: fourth, offset: 20),
          ],
        );
      },
    );

    test('a child outside the chain never reflows it', () {
      final List<MotionPathLayoutChild> children = <MotionPathLayoutChild>[
        _Child(0),
        _Child(10),
      ];
      expect(
        kGaplessLayoutDelegate.computeReflow(children, _Child(5)),
        isEmpty,
      );
    });

    test(
      'equal offsets keep insertion order, so reflow stays deterministic',
      () {
        final _Child first = _Child(0);
        final _Child tiedEarly = _Child(10);
        final _Child tiedLate = _Child(10);
        final _Child last = _Child(20);
        final List<MotionPathLayoutChild> children = <MotionPathLayoutChild>[
          first,
          tiedEarly,
          tiedLate,
          last,
        ];

        expect(
          kGaplessLayoutDelegate.computeReflow(children, tiedEarly),
          <MotionPathReflowTarget>[
            MotionPathReflowTarget(child: tiedLate, offset: 10),
            MotionPathReflowTarget(child: last, offset: 10),
          ],
        );
      },
    );
  });

  group('static policy', () {
    test('spawn placement is inherited unchanged', () {
      expect(
        kStaticLayoutDelegate.computeSpawnOffset(<MotionPathLayoutChild>[
          _Child(10),
          _Child(25),
        ], stagger: 5),
        30,
      );
    });

    test('no removal ever reflows, wherever it lands in the chain', () {
      final _Child first = _Child(0);
      final _Child middle = _Child(10);
      final _Child last = _Child(20);
      final List<MotionPathLayoutChild> children = <MotionPathLayoutChild>[
        first,
        middle,
        last,
      ];

      expect(kStaticLayoutDelegate.computeReflow(children, first), isEmpty);
      expect(kStaticLayoutDelegate.computeReflow(children, middle), isEmpty);
      expect(kStaticLayoutDelegate.computeReflow(children, last), isEmpty);
    });
  });

  group('reflow target identity', () {
    test('two targets for distinct children never compare equal', () {
      final _Child left = _Child(0);
      final _Child right = _Child(0);
      expect(
        MotionPathReflowTarget(child: left, offset: 5),
        isNot(MotionPathReflowTarget(child: right, offset: 5)),
      );
      expect(
        MotionPathReflowTarget(child: left, offset: 5),
        MotionPathReflowTarget(child: left, offset: 5),
      );
    });
  });
}
