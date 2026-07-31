import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
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
  static const double _ballRadius = 21;
  static const double _ballDuration = 12;
  static const int _waveSize = 30;

  late final MotionPathTickerDriver _ticker;
  late final MotionPathSpawnController _spawns;
  late final MotionPathSpawnTickerBinding _tickerBinding;
  late final void Function() _removeAutoSpawnListener;
  final MotionPathEngine _engine = MotionPathEngine();
  final Map<String, MotionPathPatchSource> _patchSources =
      <String, MotionPathPatchSource>{};
  final List<Offset> _guide = <Offset>[];
  double _spawnInterval = 1.25;
  double _spawnClock = 0;
  int _waveSpawned = 0;
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
    const double outerRadius = 150;
    const double innerRadius = 32;
    const double turns = 3.5;
    const int rawSegments = 2000;
    const int pathSegments = 240;
    const Offset centre = Offset(180, 180);
    final List<Offset> raw = <Offset>[];
    for (int i = 0; i <= rawSegments; i++) {
      final double p = i / rawSegments;
      final double theta = p * turns * 2 * math.pi;
      final double radius = outerRadius - (outerRadius - innerRadius) * p;
      raw.add(centre + Offset(
        radius * math.cos(theta - math.pi / 2),
        radius * math.sin(theta - math.pi / 2),
      ));
    }
    double total = 0;
    final List<double> distances = <double>[0];
    for (int i = 1; i < raw.length; i++) {
      total += (raw[i] - raw[i - 1]).distance;
      distances.add(total);
    }
    final double step = total / pathSegments;
    for (int i = 0; i <= pathSegments; i++) {
      final double target = i * step;
      int cursor = 0;
      while (cursor < distances.length - 1 && distances[cursor + 1] < target) {
        cursor++;
      }
      final double span = distances[cursor + 1] - distances[cursor];
      final double ratio = span == 0 ? 0 : (target - distances[cursor]) / span;
      _guide.add(Offset.lerp(raw[cursor], raw[cursor + 1], ratio)!);
    }
    _spawnInterval = (_ballRadius * 2) / (total / _ballDuration);
  }

  void _autoSpawn(double delta) {
    if (_waveSpawned < _waveSize) {
      _spawnClock += delta;
      while (_waveSpawned < _waveSize && _spawnClock >= _spawnInterval) {
        _spawnClock -= _spawnInterval;
        _spawn();
      }
    }
    _publishInstancePatches();
    if (_spawns.liveCount == 0 && _waveSpawned > 0) {
      _spawns.restartEmptyWave();
      _waveSpawned = 0;
      _spawnClock = 0;
      _spawn();
    }
    if (mounted) setState(() {});
  }

  void _publishInstancePatches() {
    final Set<String> live = <String>{};
    for (final MotionPathSpawnInstance instance in _spawns.instances) {
      live.add(instance.id);
      final MotionPathPatchSource source = _patchSources.putIfAbsent(
        instance.id,
        MotionPathPatchSource.new,
      );
      source.publish(<String, Map<String, Object?>>{
        instance.id: instance.patch,
      });
    }
    for (final String id in _patchSources.keys.toList()) {
      if (live.contains(id)) continue;
      _patchSources.remove(id)?.dispose();
    }
  }

  void _spawn() {
    if (_waveSpawned >= _waveSize) return;
    final String id = 'ball-${_nextId++}';
    _spawns.spawn(createAuthoredSpiralBall(id), stagger: _spawnInterval);
    _waveSpawned++;
  }

  void _pop(String id) => _spawns.remove(id);

  @override
  void dispose() {
    _removeAutoSpawnListener();
    _tickerBinding.dispose();
    _spawns.dispose();
    _ticker.dispose();
    _engine.destroy();
    for (final MotionPathPatchSource source in _patchSources.values) {
      source.dispose();
    }
    super.dispose();
  }

  Widget _balls() => Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (final MotionPathSpawnInstance instance in _spawns.instances)
            if (_patchSources[instance.id] case final MotionPathPatchSource source)
              KeyedSubtree(
                key: ValueKey<String>(instance.id),
                child: MotionPathPatchView(
                  source: source,
                  trackId: instance.id,
                  child: const _SpiralBall(),
                ),
              ),
        ],
      );

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
                  MotionPathSpawnInstance? nearest;
                  double distance = double.infinity;
                  for (final MotionPathSpawnInstance instance
                      in _spawns.instances) {
                    final MotionPathPatchTransform transform =
                        MotionPathPatchTransform.fromPatch(instance.patch);
                    final double d = Offset(
                      transform.translateX,
                      transform.translateY,
                    ).distanceTo(details.localPosition);
                    if (d < distance) {
                      distance = d;
                      nearest = instance;
                    }
                  }
                  if (nearest != null && distance < _ballRadius * 1.8) {
                    _pop(nearest.id);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    CustomPaint(
                      size: const Size(360, 360),
                      painter: _SpiralGuidePainter(_guide),
                    ),
                    _balls(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _SpiralBall extends StatelessWidget {
  const _SpiralBall();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 42,
        height: 42,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: <Color>[Color(0xFFFF6BCA), Color(0xFF00E5FF)],
            ),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 9, top: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
}

class _SpiralGuidePainter extends CustomPainter {
  const _SpiralGuidePainter(this.path);
  final List<Offset> path;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF08070D));
    final Paint guide = Paint()
      ..color = const Color(0x557C5CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (path.isEmpty) return;
    final Path spiral = Path()..moveTo(path.first.dx, path.first.dy);
    for (final Offset point in path.skip(1)) spiral.lineTo(point.dx, point.dy);
    canvas.drawPath(spiral, guide);
    final Offset centre = path.last;
    canvas.drawCircle(centre, 44, Paint()..color = const Color(0xFF160A25));
    canvas.drawCircle(centre, 29, Paint()..color = const Color(0xFF05040A));
    canvas.drawCircle(centre, 10, Paint()..color = const Color(0xAA7C5CFF));
  }
  @override
  bool shouldRepaint(covariant _SpiralGuidePainter oldDelegate) =>
      !identical(oldDelegate.path, path);
}
