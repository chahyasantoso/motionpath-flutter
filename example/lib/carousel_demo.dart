import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

/// A production-style Carousel consumer of the shared path and spawn layers.
class CarouselDemoPage extends StatefulWidget {
  const CarouselDemoPage({super.key});

  @override
  State<CarouselDemoPage> createState() => _CarouselDemoPageState();
}

class _CarouselCardData {
  const _CarouselCardData(this.badge, this.title, this.description, this.color);

  final String badge;
  final String title;
  final String description;
  final Color color;
}

class _CarouselDemoPageState extends State<CarouselDemoPage> {
  static const double _stageHeight = 560;
  static const double _cardSize = 190;
  static const double _scrollStart = 180;
  static const double _scrollEnd = 1180;
  static const List<_CarouselCardData> _templates = <_CarouselCardData>[
    _CarouselCardData('01 / IMAGINATION', 'Fluid Motion Engine', 'A shared patch drives position, opacity, and tangent rotation.', Color(0xFF6E82FF)),
    _CarouselCardData('02 / ARCHITECTURE', 'Zero Rebuilds', 'The expensive card subtree stays stable while the renderer moves it.', Color(0xFFFF6BCA)),
    _CarouselCardData('03 / CREATIVE', 'Bezier Interpolation', 'Cards follow one physical-distance sampled S-curve.', Color(0xFF00C8B3)),
    _CarouselCardData('04 / INTERACTIVE', 'Tap to Remove', 'Hit testing walks the front-most stack order before removing a card.', Color(0xFFFF8F55)),
    _CarouselCardData('05 / PERFORMANCE', 'Scrubbed Timeline', 'Scroll owns progress. There is no second animation clock.', Color(0xFF9B7CFF)),
    _CarouselCardData('06 / DYNAMIC', 'Add a Card', 'New children join the same authored path and stagger contract.', Color(0xFF4FB3FF)),
  ];

  final ScrollController _scroll = ScrollController();
  late final MotionPathTrackRuntime _parent;
  late final MotionPathSpawnController _spawns;
  int _nextId = 0;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _parent = MotionPathTrackRuntime('carousel-card-track');
    _spawns = MotionPathSpawnController(parent: _parent, childDuration: 1);
    _scroll.addListener(_onScroll);
    for (int index = 0; index < _templates.length; index++) {
      _addCard(index: index);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final double raw = ((_scroll.offset - _scrollStart) / (_scrollEnd - _scrollStart)).clamp(0.0, 1.0).toDouble();
    final double timelineEnd = math.max(1, _spawns.liveCount - 1) * 0.1 + 1;
    setState(() {
      _progress = raw;
      _spawns.advanceTo(raw * timelineEnd);
    });
  }

  void _addCard({int? index}) {
    final int cardIndex = index ?? _nextId++ % _templates.length;
    final _CarouselCardData data = _templates[cardIndex];
    final String id = 'carousel-${_nextId++}';
    _spawns.spawn(
      MotionPathTrackRuntime(
        id,
        properties: <String, List<MotionPathStop>>{
          'path': <MotionPathStop>[
            MotionPathStop(
              progress: 0,
              value: <String, Object?>{
                'points': <Object?>[
                  <String, Object?>{'x': -260, 'y': 310},
                  <String, Object?>{'x': 200, 'y': 130, 'ctrlX': -20, 'ctrlY': 70},
                  <String, Object?>{'x': 660, 'y': 360, 'ctrlX': 520, 'ctrlY': 180},
                  <String, Object?>{'x': 1120, 'y': 150, 'ctrlX': 900, 'ctrlY': 560},
                  <String, Object?>{'x': 1520, 'y': 300, 'ctrlX': 1320, 'ctrlY': -80},
                ],
                'autoRotate': true,
              },
            ),
            MotionPathStop(
              progress: 1,
              value: <String, Object?>{
                'points': <Object?>[
                  <String, Object?>{'x': -260, 'y': 310},
                  <String, Object?>{'x': 200, 'y': 130, 'ctrlX': -20, 'ctrlY': 70},
                  <String, Object?>{'x': 660, 'y': 360, 'ctrlX': 520, 'ctrlY': 180},
                  <String, Object?>{'x': 1120, 'y': 150, 'ctrlX': 900, 'ctrlY': 560},
                  <String, Object?>{'x': 1520, 'y': 300, 'ctrlX': 1320, 'ctrlY': -80},
                ],
                'autoRotate': true,
              },
            ),
          ],
          'opacity': <MotionPathStop>[
            const MotionPathStop(progress: 0, value: 0),
            const MotionPathStop(progress: 0.15, value: 1),
            const MotionPathStop(progress: 0.85, value: 1),
            const MotionPathStop(progress: 1, value: 0),
          ],
        },
      ),
      stagger: 0.1,
    );
    _cardData[id] = data;
    if (mounted) setState(() {});
  }

  final Map<String, _CarouselCardData> _cardData = <String, _CarouselCardData>{};

  void _removeCard(String id) {
    _spawns.remove(id);
    _cardData.remove(id);
    setState(() {});
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _spawns.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF08070D),
        appBar: AppBar(
          title: const Text('MotionPath Carousel'),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${(_progress * 100).round()}% scrubbed')),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addCard,
          icon: const Icon(Icons.add),
          label: const Text('Add card'),
        ),
        body: ListView(
          controller: _scroll,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 48, 24, 72),
              child: Text(
                'One path. Dynamic children. Zero demo-only math.',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(
              height: _stageHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: <Widget>[
                  Positioned.fill(child: CustomPaint(painter: _CarouselGuidePainter())),
                  Positioned.fill(
                    child: MotionPathSpawnView(
                      controller: _spawns,
                      itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) {
                        final _CarouselCardData data = _cardData[instance.id] ?? _templates.first;
                        return _CarouselCard(data: data, size: _cardSize);
                      },
                      onHit: (MotionPathSpawnInstance instance, Offset localPosition) {
                        final MotionPathPatchTransform transform = MotionPathPatchTransform.fromPatch(instance.patch);
                        final Rect bounds = Rect.fromCenter(center: Offset(transform.translateX, transform.translateY), width: _cardSize, height: _cardSize);
                        if (bounds.contains(localPosition)) {
                          _removeCard(instance.id);
                          return true;
                        }
                        return false;
                      },
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 24,
                    child: Text('${_spawns.liveCount} cards  •  scroll to scrub  •  tap to remove', style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 720),
          ],
        ),
      );
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.data, required this.size});

  final _CarouselCardData data;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 12))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1),
                ),
                const Spacer(),
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    data.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.25),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CarouselGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF10101D));
    final Paint line = Paint()..color = const Color(0x337C5CFF)..style = PaintingStyle.stroke..strokeWidth = 2;
    final Path path = Path()..moveTo(-260, 310)..cubicTo(-20, 70, -20, 70, 200, 130)..cubicTo(520, 180, 520, 180, 660, 360)..cubicTo(900, 560, 900, 560, 1120, 150)..cubicTo(1320, -80, 1320, -80, 1520, 300);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _CarouselGuidePainter oldDelegate) => false;
}
