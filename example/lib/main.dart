import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

void main() => runApp(const MotionPathExampleApp());

class MotionPathExampleApp extends StatelessWidget {
  const MotionPathExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: const MotionPathExamplePage(),
  );
}

class MotionPathExamplePage extends StatefulWidget {
  const MotionPathExamplePage({super.key});

  @override
  State<MotionPathExamplePage> createState() => _MotionPathExamplePageState();
}

class _MotionPathExamplePageState extends State<MotionPathExamplePage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final MotionPathEngine _engine;
  late final MotionPathTickerDriver _ticker;
  late final MotionPathMotionRuntime _viewportMotion;
  late final MotionPathPatchSource _source;
  late final MotionPathViewportBinding _viewport;
  late final MotionPathTrackRuntime _spawnParent;
  late final MotionPathSpawnController _spawns;
  late final MotionPathSpawnTickerBinding _spawnTicker;
  int _nextSpawnId = 0;

  @override
  void initState() {
    super.initState();
    _engine = MotionPathEngine();
    _ticker = MotionPathTickerDriver(_engine, this);
    _viewportMotion = MotionPathMotionRuntime(
      id: 'viewport',
      tracks: <MotionPathTrackRuntime>[
        MotionPathTrackRuntime(
          'viewport-progress',
          properties: <String, List<MotionPathStop>>{
            'opacity': const <MotionPathStop>[
              MotionPathStop(progress: 0, value: 0.35),
              MotionPathStop(progress: 1, value: 1),
            ],
          },
        ),
      ],
    );
    _source = MotionPathPatchSource()..bind(_viewportMotion);
    _viewport = MotionPathViewportBinding(
      motion: _viewportMotion,
      itemStart: 360,
      itemExtent: 220,
      viewportExtent: 420,
      start: 220,
      end: 640,
      pin: true,
      onSample: (_) => _source.publish(_viewportMotion.composeGraph()),
    );

    _spawnParent = MotionPathTrackRuntime('spawn-parent');
    _spawns = MotionPathSpawnController(
      parent: _spawnParent,
      childDuration: 9999,
      drainOnComplete: false,
    );
    _spawnTicker = MotionPathSpawnTickerBinding(
      driver: _ticker,
      controller: _spawns,
    );
    _ticker.start();
    _scroll.addListener(_sampleViewport);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sampleViewport());
  }

  void _sampleViewport() {
    if (!_scroll.hasClients || _viewport.isDisposed) return;
    _viewport.sampleFromOffset(_scroll.offset);
    _source.publish(_viewportMotion.composeGraph());
  }

  void _spawn() {
    final String id = 'dot-${_nextSpawnId++}';
    _spawns.spawn(
      MotionPathTrackRuntime(
        id,
        properties: <String, List<MotionPathStop>>{
          'progress': const <MotionPathStop>[
            MotionPathStop(progress: 0, value: 0),
            MotionPathStop(progress: 1, value: 1),
          ],
        },
      ),
      stagger: 0.45,
    );
  }

  @override
  void dispose() {
    _scroll.removeListener(_sampleViewport);
    _viewport.dispose();
    _spawnTicker.dispose();
    _spawns.dispose();
    _ticker.dispose();
    _engine.destroy();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MotionPath Flutter')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _spawn,
      icon: const Icon(Icons.add),
      label: const Text('Spawn dot'),
    ),
    body: ListView(
      controller: _scroll,
      children: <Widget>[
        const _IntroCard(),
        SizedBox(
          height: 420,
          child: AnimatedBuilder(
            animation: _source,
            builder: (BuildContext context, Widget? child) => Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ViewportPainter(sample: _viewport.sample),
                  ),
                ),
                if (_viewport.sample.pinned)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: Chip(label: Text('PINNED')),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 360,
          child: AnimatedBuilder(
            animation: _spawns,
            builder: (BuildContext context, Widget? child) => Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpawnPainter(instances: _spawns.instances),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 20,
                  child: Text(
                    '${_spawns.liveCount} dots in the chain',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 600),
      ],
    ),
  );
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Text(
      'Scroll to observe viewport progress and pin state. Tap Spawn dot to build a visible chain. Dots stay mounted here so the instance count is easy to inspect.',
      style: TextStyle(fontSize: 18),
    ),
  );
}

class _ViewportPainter extends CustomPainter {
  const _ViewportPainter({required this.sample});
  final MotionPathViewportSample sample;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF151A2B),
    );
    final double y = sample.pinned
        ? 60
        : sample.localOffset.clamp(0, size.height);
    final Paint card = Paint()
      ..color = Color.lerp(
        const Color(0xFF384A80),
        const Color(0xFF6E82FF),
        sample.progress,
      )!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24, y, size.width - 48, 220),
        const Radius.circular(24),
      ),
      card,
    );
    final TextPainter text = TextPainter(
      text: TextSpan(
        text: 'progress ${(sample.progress * 100).round()}%',
        style: const TextStyle(color: Colors.white, fontSize: 22),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(48, 84));
  }

  @override
  bool shouldRepaint(covariant _ViewportPainter oldDelegate) =>
      oldDelegate.sample != sample;
}

class _SpawnPainter extends CustomPainter {
  const _SpawnPainter({required this.instances});
  final List<MotionPathSpawnInstance> instances;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B0D16),
    );
    final double span = size.width - 72;
    for (final MotionPathSpawnInstance instance in instances) {
      final double x = 36 + (instance.offset * 78) % span;
      final double y = size.height / 2 + (instance.offset * 24) % 90 - 45;
      final double radius = 10 + instance.progress * 8;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFF8F55),
            const Color(0xFF6E82FF),
            instance.progress,
          )!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpawnPainter oldDelegate) =>
      oldDelegate.instances != instances;
}
