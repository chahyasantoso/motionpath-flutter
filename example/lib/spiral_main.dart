import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

import 'spiral_project.dart';

void main() => runApp(const SpiralZumaApp());

class SpiralZumaApp extends StatelessWidget {
  const SpiralZumaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const SpiralZumaPage(),
      );
}

class SpiralZumaPage extends StatefulWidget {
  const SpiralZumaPage({super.key});

  @override
  State<SpiralZumaPage> createState() => _SpiralZumaPageState();
}

class _SpiralZumaPageState extends State<SpiralZumaPage>
    with SingleTickerProviderStateMixin {
  static const double _spawnInterval = 1.25;
  static const double _ballRadius = 21;
  static const double _ballDuration = 12;

  late final MotionPathTickerDriver _ticker;
  late final MotionPathSpawnController _spawns;
  late final MotionPathSpawnTickerBinding _tickerBinding;
  late final void Function() _removeAutoSpawnListener;
  final MotionPathEngine _engine = MotionPathEngine();
  final List<Offset> _spiral = <Offset>[];
  double _spawnClock = 0;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _buildSpiral();
    _ticker = MotionPathTickerDriver(_engine, this);
    _spawns = MotionPathSpawnController(
      parent: MotionPathTrackRuntime('spiral-parent'),
      childDuration: _ballDuration,
      drainOnComplete: true,
    );
    _tickerBinding = MotionPathSpawnTickerBinding(
      driver: _ticker,
      controller: _spawns,
    );
    _removeAutoSpawnListener = _ticker.addTickListener(_autoSpawn);
    _ticker.start();
    _spawn();
  }

  void _buildSpiral() {
    const Offset centre = Offset(180, 180);
    const int segments = 240;
    for (int index = 0; index <= segments; index++) {
      final double t = index / segments;
      final double radius = 150 - t * 118;
      final double angle = t * math.pi * 7 - math.pi / 2;
      _spiral.add(centre + Offset(math.cos(angle) * radius, math.sin(angle) * radius));
    }
  }

  void _autoSpawn(double delta) {
    _spawnClock += delta;
    while (_spawnClock >= _spawnInterval) {
      _spawnClock -= _spawnInterval;
      _spawn();
    }
    if (_spawns.liveCount == 0) {
      _spawnClock = 0;
      _spawn();
    }
  }

  void _spawn() {
    final String id = 'ball-${_nextId++}';
    _spawns.spawn(
      createAuthoredSpiralBall(id),
      stagger: _ballRadius * 2 / 110,
    );
  }

  void _pop(String id) {
    _spawns.remove(id);
    if (_spawns.liveCount == 0) {
      _spawnClock = 0;
      _spawn();
    }
  }

  @override
  void dispose() {
    _removeAutoSpawnListener();
    _tickerBinding.dispose();
    _spawns.dispose();
    _ticker.dispose();
    _engine.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF08070D),
        appBar: AppBar(
          title: const Text('Zuma / Spiral'),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(child: Text('${_spawns.liveCount} balls')),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _spawn,
          icon: const Icon(Icons.add),
          label: const Text('Add ball'),
        ),
        body: AnimatedBuilder(
          animation: _spawns,
          builder: (BuildContext context, Widget? child) => Center(
            child: SizedBox(
              width: 360,
              height: 360,
              child: GestureDetector(
                onTapUp: (TapUpDetails details) {
                  final Offset point = details.localPosition;
                  MotionPathSpawnInstance? nearest;
                  double distance = double.infinity;
                  for (final MotionPathSpawnInstance instance in _spawns.instances) {
                    final Offset ball = _ballPosition(instance);
                    final double d = (ball - point).distance;
                    if (d < distance) {
                      distance = d;
                      nearest = instance;
                    }
                  }
                  if (nearest != null && distance < _ballRadius * 1.8) {
                    _pop(nearest.id);
                  }
                },
                child: CustomPaint(
                  painter: _SpiralPainter(
                    path: _spiral,
                    instances: _spawns.instances,
                    positionOf: _ballPosition,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Offset _ballPosition(MotionPathSpawnInstance instance) {
    final int index = (instance.progress.clamp(0.0, 1.0) * (_spiral.length - 1)).round();
    return _spiral[index];
  }
}

class _SpiralPainter extends CustomPainter {
  const _SpiralPainter({required this.path, required this.instances, required this.positionOf});
  final List<Offset> path;
  final List<MotionPathSpawnInstance> instances;
  final Offset Function(MotionPathSpawnInstance) positionOf;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF08070D));
    final Paint guide = Paint()
      ..color = const Color(0x557C5CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final Path spiral = Path()..moveTo(path.first.dx, path.first.dy);
    for (final Offset point in path.skip(1)) {
      spiral.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(spiral, guide);
    final Offset centre = path.last;
    canvas.drawCircle(centre, 44, Paint()..color = const Color(0xFF160A25));
    canvas.drawCircle(centre, 29, Paint()..color = const Color(0xFF05040A));
    canvas.drawCircle(centre, 10, Paint()..color = const Color(0xAA7C5CFF));

    for (final MotionPathSpawnInstance instance in instances) {
      final Offset point = positionOf(instance);
      final double opacity = instance.hasStarted ? 1 : 0.35;
      final Color base = Color.lerp(
        const Color(0xFFFF6BCA),
        const Color(0xFF00E5FF),
        instance.progress,
      )!;
      final Paint ball = Paint()..color = _withOpacity(base, opacity);
      canvas.drawCircle(point, _SpiralZumaPageState._ballRadius, ball);
      canvas.drawCircle(
        point + const Offset(-6, -6),
        5,
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpiralPainter oldDelegate) => oldDelegate.instances != instances;
}

Color _withOpacity(Color color, double opacity) => Color.fromARGB(
      ((color.alpha * opacity).round().clamp(0, 255)).toInt(),
      color.red,
      color.green,
      color.blue,
    );
