import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

import 'motorcycle_scene.dart';

/// Scroll runway, in logical pixels, mapped onto the ride timeline.
///
/// This is host chrome, not authored motion: the scene contract owns every
/// keyframe and the runway only decides how much scrolling spends it.
const double motorcycleScrollSpan = 1100;

/// Authored stage the road, cloud, and streak nodes are expressed in.
const Size motorcycleStageSize = Size(1280, 620);

/// Back-to-front layering for the authored tracks.
///
/// The JS page inherits stacking from DOM order. The scene contract owns
/// motion only, so the host owns layering. Unlisted tracks keep their
/// authored order in front of these.
const List<String> motorcyclePaintOrder = <String>[
  'moto-cloud-a',
  'moto-cloud-b',
  'moto-streak-a',
  'moto-streak-b',
  'moto-shadow',
  'moto-bike',
];

class MotorcycleDemoPage extends StatefulWidget {
  const MotorcycleDemoPage({super.key});

  @override
  State<MotorcycleDemoPage> createState() => _MotorcycleDemoPageState();
}

class _MotorcycleDemoPageState extends State<MotorcycleDemoPage> {
  final ScrollController _scroll = ScrollController();
  late final MotionPathSpawnController _spawns;
  late final MotionPathScrollDriver _driver;

  @override
  void initState() {
    super.initState();
    final MotionPathTrackRuntime parent = MotionPathTrackRuntime('motorcycle');
    _spawns = MotionPathSpawnController(parent: parent);
    final Map<String, MotionPathTrackRuntime> byId =
        <String, MotionPathTrackRuntime>{
      for (final MotionPathTrackRuntime track in motorcycleSceneTracks())
        track.id: track,
    };
    for (final String id in motorcyclePaintOrder) {
      final MotionPathTrackRuntime? track = byId.remove(id);
      if (track != null) _spawns.spawn(track);
    }
    for (final MotionPathTrackRuntime track in byId.values) {
      _spawns.spawn(track);
    }
    _driver = MotionPathScrollDriver(
      binding: const MotionPathScrollBinding(end: motorcycleScrollSpan),
      onProgress: _onProgress,
    );
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _driver.attach(_scroll);
    });
  }

  /// Scroll spends the authored ride duration.
  ///
  /// Clouds and streaks keep their own duration tiers, so the same scroll
  /// leaves the clouds mid-drift while the streaks whip past the bike.
  void _onProgress(double progress) =>
      _spawns.advanceTo(progress * motorcycleRideDuration);

  @override
  void dispose() {
    _driver.dispose();
    _spawns.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0A1020),
        appBar: AppBar(
          title: const Text('MotionPath Motorcycle'),
          actions: const <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: Text('scroll-driven ride')),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const _MotorcycleSky(),
              Center(
                child: FittedBox(
                  child: SizedBox(
                    width: motorcycleStageSize.width,
                    height: motorcycleStageSize.height,
                    child: MotionPathSpawnView(
                      controller: _spawns,
                      itemBuilder: (
                        BuildContext context,
                        MotionPathSpawnInstance instance,
                      ) =>
                          _MotorcycleSprite(id: instance.id),
                    ),
                  ),
                ),
              ),
              // Transparent runway. The stage stays put while this scrolls, so
              // the whole ride is visible across the authored timeline.
              ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  SizedBox(height: constraints.maxHeight + motorcycleScrollSpan),
                ],
              ),
            ],
          ),
        ),
      );
}

/// Centers authored art on its composed path point.
///
/// The spawn view translates and rotates the child's box origin, so a
/// zero-size box keeps both anchored exactly on the sampled path point.
Widget _pin(String id, Size size, Widget child) => SizedBox.shrink(
      key: ValueKey<String>('moto-art-$id'),
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    );

class _MotorcycleSprite extends StatelessWidget {
  const _MotorcycleSprite({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case 'moto-bike':
        return _pin(id, const Size(196, 116), const _BikeArt());
      case 'moto-shadow':
        return _pin(id, const Size(186, 34), const _ShadowArt());
      case 'moto-cloud-a':
        return _pin(
          id,
          const Size(340, 128),
          const _CloudArt(tint: Color(0x59FFFFFF)),
        );
      case 'moto-cloud-b':
        return _pin(
          id,
          const Size(252, 100),
          const _CloudArt(tint: Color(0x3DFFFFFF)),
        );
      case 'moto-streak-a':
        return _pin(id, const Size(280, 10), const _StreakArt(thickness: 5));
      case 'moto-streak-b':
        return _pin(id, const Size(210, 8), const _StreakArt(thickness: 3));
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BikeArt extends StatelessWidget {
  const _BikeArt();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _BikePainter());
}

class _BikePainter extends CustomPainter {
  const _BikePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double radius = h * 0.25;
    final Offset rear = Offset(w * 0.22, h * 0.72);
    final Offset front = Offset(w * 0.80, h * 0.72);

    final Paint tyre = Paint()
      ..color = const Color(0xFF13161F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.09;
    final Paint rim = Paint()
      ..color = const Color(0xFF9FB4D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.03;
    canvas
      ..drawCircle(rear, radius, tyre)
      ..drawCircle(front, radius, tyre)
      ..drawCircle(rear, radius * 0.52, rim)
      ..drawCircle(front, radius * 0.52, rim);

    final Path frame = Path()
      ..moveTo(w * 0.18, h * 0.62)
      ..lineTo(w * 0.44, h * 0.42)
      ..lineTo(w * 0.66, h * 0.44)
      ..lineTo(w * 0.78, h * 0.60)
      ..lineTo(w * 0.62, h * 0.64)
      ..lineTo(w * 0.40, h * 0.60)
      ..close();
    canvas.drawPath(frame, Paint()..color = const Color(0xFFE24B3C));

    final Paint metal = Paint()
      ..color = const Color(0xFFB9C6DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.045
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(w * 0.78, h * 0.60), Offset(w * 0.86, h * 0.34), metal)
      ..drawLine(Offset(w * 0.86, h * 0.34), Offset(w * 0.96, h * 0.36), metal);

    final Path rider = Path()
      ..moveTo(w * 0.32, h * 0.54)
      ..lineTo(w * 0.48, h * 0.20)
      ..lineTo(w * 0.64, h * 0.24)
      ..lineTo(w * 0.82, h * 0.38)
      ..lineTo(w * 0.62, h * 0.42)
      ..lineTo(w * 0.46, h * 0.52)
      ..close();
    canvas
      ..drawPath(rider, Paint()..color = const Color(0xFF22304F))
      ..drawCircle(
        Offset(w * 0.54, h * 0.15),
        h * 0.11,
        Paint()..color = const Color(0xFFF2C79A),
      );
  }

  @override
  bool shouldRepaint(_BikePainter oldDelegate) => false;
}

class _ShadowArt extends StatelessWidget {
  const _ShadowArt();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x4D000000),
          borderRadius: BorderRadius.all(Radius.elliptical(93, 17)),
        ),
      );
}

class _CloudArt extends StatelessWidget {
  const _CloudArt({required this.tint});

  final Color tint;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _CloudPainter(tint));
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter(this.tint);

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = tint;
    canvas
      ..drawCircle(
        Offset(size.width * 0.28, size.height * 0.60),
        size.height * 0.32,
        paint,
      )
      ..drawCircle(
        Offset(size.width * 0.50, size.height * 0.46),
        size.height * 0.42,
        paint,
      )
      ..drawCircle(
        Offset(size.width * 0.72, size.height * 0.60),
        size.height * 0.30,
        paint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.18,
            size.height * 0.58,
            size.width * 0.64,
            size.height * 0.30,
          ),
          Radius.circular(size.height * 0.16),
        ),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) => oldDelegate.tint != tint;
}

class _StreakArt extends StatelessWidget {
  const _StreakArt({required this.thickness});

  final double thickness;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: double.infinity,
          height: thickness,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(thickness),
              gradient: const LinearGradient(
                colors: <Color>[
                  Color(0x00A9E7FF),
                  Color(0xCCA9E7FF),
                  Color(0x00A9E7FF),
                ],
              ),
            ),
          ),
        ),
      );
}

class _MotorcycleSky extends StatelessWidget {
  const _MotorcycleSky();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF15224A),
              Color(0xFF2B3F72),
              Color(0xFF0A1020),
            ],
          ),
        ),
        child: SizedBox.expand(),
      );
}
