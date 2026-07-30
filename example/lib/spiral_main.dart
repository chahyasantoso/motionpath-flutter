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

class _BallVisual {
  _BallVisual({required this.id, required this.offset}) : targetOffset = offset;
  final String id;
  double offset;
  double targetOffset;
  double entranceAge = 0;
  double reflowAge = 1;
  double exitAge = 0;
  Offset lastPosition = Offset.zero;
  double progress = 0;
}

class _SpiralZumaPageState extends State<SpiralZumaPage>
    with SingleTickerProviderStateMixin {
  static const double _ballRadius = 21;
  static const double _ballDuration = 12;
  static const double _entranceDuration = 0.35;
  static const double _exitDuration = 0.35;
  static const double _reflowDuration = 0.55;
  static const int _waveSize = 30;
  static const int _rawSegments = 2000;
  static const int _pathSegments = 240;

  late final MotionPathTickerDriver _ticker;
  late final MotionPathSpawnController _spawns;
  late final MotionPathSpawnTickerBinding _tickerBinding;
  late final void Function() _removeAutoSpawnListener;
  final MotionPathEngine _engine = MotionPathEngine();
  final List<Offset> _spiral = <Offset>[];
  final Map<String, _BallVisual> _visuals = <String, _BallVisual>{};
  final List<_BallVisual> _exiting = <_BallVisual>[];
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
    _tickerBinding = MotionPathSpawnTickerBinding(driver: _ticker, controller: _spawns);
    _removeAutoSpawnListener = _ticker.addTickListener(_autoSpawn);
    _ticker.start();
    _spawn();
  }

  void _buildSpiral() {
    const Offset centre = Offset(180, 180);
    const double outerRadius = 150;
    const double innerRadius = 32;
    const double turns = 3.5;
    final List<Offset> raw = <Offset>[];
    for (int i = 0; i <= _rawSegments; i++) {
      final double p = i / _rawSegments;
      final double theta = p * turns * 2 * math.pi;
      final double radius = outerRadius - (outerRadius - innerRadius) * p;
      raw.add(centre + Offset(radius * math.cos(theta - math.pi / 2), radius * math.sin(theta - math.pi / 2)));
    }
    final List<double> distances = <double>[0];
    double total = 0;
    for (int i = 1; i < raw.length; i++) {
      total += (raw[i] - raw[i - 1]).distance;
      distances.add(total);
    }
    final double step = total / _pathSegments;
    for (int i = 0; i <= _pathSegments; i++) {
      final double target = i * step;
      int cursor = 0;
      while (cursor < distances.length - 1 && distances[cursor + 1] < target) cursor++;
      final double span = distances[cursor + 1] - distances[cursor];
      final double ratio = span == 0 ? 0 : (target - distances[cursor]) / span;
      _spiral.add(Offset.lerp(raw[cursor], raw[cursor + 1], ratio)!);
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
    _syncVisuals(delta);
    if (_spawns.liveCount == 0 && _waveSpawned > 0) {
      // JS Spawner.resetWave() + hostTrack.seek(0): the next wave starts at
      // the outer endpoint, never at the old drained timeline offset.
      _spawns.restartEmptyWave();
      _waveSpawned = 0;
      _spawnClock = 0;
      _spawn();
    }
    if (mounted) setState(() {});
  }

  void _syncVisuals(double delta) {
    final Set<String> live = <String>{};
    for (final MotionPathSpawnInstance instance in _spawns.instances) {
      live.add(instance.id);
      final _BallVisual visual = _visuals.putIfAbsent(instance.id, () => _BallVisual(id: instance.id, offset: instance.offset));
      if ((visual.targetOffset - instance.offset).abs() > 1e-6) {
        visual.offset = _displayOffset(visual);
        visual.targetOffset = instance.offset;
        visual.reflowAge = 0;
      }
      visual.entranceAge = (visual.entranceAge + delta).clamp(0, _entranceDuration).toDouble();
      visual.reflowAge = (visual.reflowAge + delta).clamp(0, _reflowDuration).toDouble();
      visual.progress = ((_spawns.elapsed - _displayOffset(visual)) / _ballDuration).clamp(0.0, 1.0).toDouble();
      visual.lastPosition = _position(visual.progress);
    }
    for (final String id in _visuals.keys.toList()) {
      if (live.contains(id)) continue;
      final _BallVisual visual = _visuals.remove(id)!;
      visual.exitAge = 0;
      visual.progress = 1;
      _exiting.add(visual);
    }
    for (final _BallVisual visual in _exiting) visual.exitAge += delta;
    _exiting.removeWhere((visual) => visual.exitAge >= _exitDuration);
  }

  double _displayOffset(_BallVisual visual) {
    if (visual.reflowAge >= _reflowDuration) return visual.targetOffset;
    final double t = (visual.reflowAge / _reflowDuration).clamp(0.0, 1.0);
    return visual.offset + (visual.targetOffset - visual.offset) * (1 - math.pow(1 - t, 2).toDouble());
  }

  Offset _position(double progress) {
    final int index = (progress.clamp(0.0, 1.0) * (_spiral.length - 1)).round();
    return _spiral[index];
  }

  void _spawn() {
    if (_waveSpawned >= _waveSize) return;
    final String id = 'ball-${_nextId++}';
    _spawns.spawn(createAuthoredSpiralBall(id), stagger: _spawnInterval);
    _waveSpawned++;
  }

  void _pop(String id) {
    if (_visuals.containsKey(id)) _spawns.remove(id);
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
          actions: <Widget>[Padding(padding: const EdgeInsets.only(right: 20), child: Center(child: Text('${_spawns.liveCount} balls')))],
        ),
        floatingActionButton: FloatingActionButton.extended(onPressed: _spawn, icon: const Icon(Icons.add), label: const Text('Add ball')),
        body: AnimatedBuilder(
          animation: _spawns,
          builder: (BuildContext context, Widget? child) => Center(
            child: SizedBox(
              width: 360,
              height: 360,
              child: GestureDetector(
                onTapUp: (TapUpDetails details) {
                  String? nearest;
                  double distance = double.infinity;
                  for (final MotionPathSpawnInstance instance in _spawns.instances) {
                    final _BallVisual? visual = _visuals[instance.id];
                    if (visual == null) continue;
                    final double d = (_position(visual.progress) - details.localPosition).distance;
                    if (d < distance) { distance = d; nearest = instance.id; }
                  }
                  if (nearest != null && distance < _ballRadius * 1.8) _pop(nearest);
                },
                child: CustomPaint(painter: _SpiralPainter(path: _spiral, instances: _spawns.instances, visuals: _visuals, exiting: _exiting)),
              ),
            ),
          ),
        ),
      );
}

class _SpiralPainter extends CustomPainter {
  const _SpiralPainter({required this.path, required this.instances, required this.visuals, required this.exiting});
  final List<Offset> path;
  final List<MotionPathSpawnInstance> instances;
  final Map<String, _BallVisual> visuals;
  final List<_BallVisual> exiting;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF08070D));
    final Paint guide = Paint()..color = const Color(0x557C5CFF)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round;
    final Path spiral = Path()..moveTo(path.first.dx, path.first.dy);
    for (final Offset point in path.skip(1)) spiral.lineTo(point.dx, point.dy);
    canvas.drawPath(spiral, guide);
    final Offset centre = path.last;
    canvas.drawCircle(centre, 44, Paint()..color = const Color(0xFF160A25));
    canvas.drawCircle(centre, 29, Paint()..color = const Color(0xFF05040A));
    canvas.drawCircle(centre, 10, Paint()..color = const Color(0xAA7C5CFF));
    for (final MotionPathSpawnInstance instance in instances) {
      final _BallVisual? visual = visuals[instance.id];
      if (visual == null || !instance.hasStarted) continue;
      final double entrance = (visual.entranceAge / _SpiralZumaPageState._entranceDuration).clamp(0.0, 1.0);
      _drawBall(canvas, _pathPosition(path, visual.progress), entrance, 1 + 0.7 * math.sin(math.pi * entrance), visual.progress);
    }
    for (final _BallVisual visual in exiting) {
      final double t = (visual.exitAge / _SpiralZumaPageState._exitDuration).clamp(0.0, 1.0);
      _drawBall(canvas, visual.lastPosition, 1 - t, 1 + 0.7 * t, 1);
    }
  }

  void _drawBall(Canvas canvas, Offset point, double opacity, double scale, double progress) {
    final Color base = Color.lerp(const Color(0xFFFF6BCA), const Color(0xFF00E5FF), progress.clamp(0.0, 1.0))!;
    canvas.drawCircle(point, _SpiralZumaPageState._ballRadius * scale, Paint()..color = _withOpacity(base, opacity));
    canvas.drawCircle(point + const Offset(-6, -6), 5 * scale, Paint()..color = _withOpacity(Colors.white, opacity));
  }
  @override
  bool shouldRepaint(covariant _SpiralPainter oldDelegate) => true;
}

Offset _pathPosition(List<Offset> path, double progress) {
  final int index = (progress.clamp(0.0, 1.0) * (path.length - 1)).round();
  return path[index];
}

int _channel(double channel) => (channel * 255).round().clamp(0, 255).toInt();
Color _withOpacity(Color color, double opacity) => Color.fromARGB((_channel(color.a) * opacity).round().clamp(0, 255).toInt(), _channel(color.r), _channel(color.g), _channel(color.b));
