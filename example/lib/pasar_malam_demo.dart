import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

import 'pasar_malam_scene.dart';

const double pasarMalamScrollSpan = 1200;
const Size pasarMalamStageSize = Size(900, 620);

class PasarMalamDemoPage extends StatefulWidget {
  const PasarMalamDemoPage({super.key});

  @override
  State<PasarMalamDemoPage> createState() => _PasarMalamDemoPageState();
}

class _PasarMalamDemoPageState extends State<PasarMalamDemoPage> {
  final ScrollController _scroll = ScrollController();
  late final MotionPathSpawnController _spawns;
  late final MotionPathScrollDriver _driver;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    final MotionPathTrackRuntime parent = MotionPathTrackRuntime('pasar-malam');
    _spawns = MotionPathSpawnController(parent: parent);
    for (final MotionPathTrackRuntime track in pasarMalamStoryTracks()) {
      if (track.id != 'pasar-malam-bg') _spawns.spawn(track);
    }
    _driver = MotionPathScrollDriver(
      binding: const MotionPathScrollBinding(end: pasarMalamScrollSpan),
      onProgress: _onProgress,
    );
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _driver.attach(_scroll);
    });
  }

  void _onProgress(double progress) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _spawns.advanceTo(progress);
    });
  }

  @override
  void dispose() {
    _driver.dispose();
    _spawns.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080A1A),
        appBar: AppBar(
          title: const Text('MotionPath Pasar Malam'),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${(_progress * 100).round()}% scrubbed')),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _PasarMalamBackdrop(progress: _progress),
              Center(
                child: FittedBox(
                  child: SizedBox(
                    width: pasarMalamStageSize.width,
                    height: pasarMalamStageSize.height,
                    child: MotionPathSpawnView(
                      alignment: Alignment.center,
                      controller: _spawns,
                      itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) =>
                          _PasarMalamItem(id: instance.id),
                    ),
                  ),
                ),
              ),
              ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  SizedBox(height: constraints.maxHeight + pasarMalamScrollSpan),
                  const _PasarMalamFooter(),
                ],
              ),
            ],
          ),
        ),
      );
}

class _PasarMalamBackdrop extends StatelessWidget {
  const _PasarMalamBackdrop({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final int frame = (progress * (pasarMalamFrameCount - 1)).round() + 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(const Color(0xFF05051A), const Color(0xFF301052), progress)!,
            Color.lerp(const Color(0xFF10102B), const Color(0xFF07162B), progress)!,
            const Color(0xFF050611),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: Text(
              'FRAME ${frame.toString().padLeft(4, '0')}',
              style: const TextStyle(color: Colors.white24, letterSpacing: 3),
            ),
          ),
          Positioned(
            top: 48,
            left: 24,
            child: Text(
              '192-frame night market sequence',
              style: const TextStyle(color: Colors.white54, letterSpacing: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasarMalamItem extends StatelessWidget {
  const _PasarMalamItem({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case 'hero-title':
        return const _HeroTitle();
      case 'card-left':
        return const _MarketCard(
          badge: 'STREET FLAVORS',
          title: 'Nostalgic Tastes',
          body: 'Fresh Apam Balik, grilled Satay, and spun sugar under colorful lights.',
          accent: Color(0xFFFF0080),
        );
      case 'card-right':
        return const _MarketCard(
          badge: 'NIGHT VIBES',
          title: 'Carnival Thrills',
          body: 'Neon games, music, and laughter light up the tropical midnight sky.',
          accent: Color(0xFF00E5FF),
        );
      case 'stats-card':
        return const _StatsCard();
      case 'lantern-1-wrap':
        return const _Lantern(color: Color(0xFFFF416C), icon: '✦');
      case 'lantern-2-wrap':
        return const _Lantern(color: Color(0xFFFFD166), icon: '✧');
      case 'lantern-3-wrap':
        return const _Lantern(color: Color(0xFFFF82C8), icon: '✦');
      default:
        return const SizedBox.shrink();
    }
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Pasar Malam', style: TextStyle(fontSize: 62, fontWeight: FontWeight.w900, letterSpacing: -2)),
            Text('THE NIGHT AWAKENS', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 14, letterSpacing: 5, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.badge, required this.title, required this.body, required this.accent});

  final String badge;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 250,
        height: 210,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xAA14152F),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.65)),
            boxShadow: <BoxShadow>[BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 30)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(badge, style: TextStyle(color: accent, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Expanded(child: Text(body, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, height: 1.3))),
            ]),
          ),
        ),
      );
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 250,
        height: 120,
        child: DecoratedBox(
          decoration: BoxDecoration(color: const Color(0xDD17152F), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFF0080))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
            _Stat(value: '192+', label: 'STALLS'),
            _Stat(value: '10K', label: 'VISITORS'),
          ]),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFF82C8))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 1.4, color: Colors.white54)),
      ]);
}

class _Lantern extends StatelessWidget {
  const _Lantern({required this.color, required this.icon});
  final Color color;
  final String icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 100,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(36), boxShadow: <BoxShadow>[BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 28)]),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 30, color: Colors.white))),
      );
}

class _PasarMalamFooter extends StatelessWidget {
  const _PasarMalamFooter();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(48),
        child: Text('Scroll up to replay the night market story', style: TextStyle(color: Colors.white54, fontSize: 18)),
      );
}
