import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

import 'pasar_malam_scene.dart';

const double pasarMalamObserverScrollSpan = 1200;
const Size pasarMalamObserverStageSize = Size(900, 620);

class PasarMalamObserverDemoPage extends StatefulWidget {
  const PasarMalamObserverDemoPage({super.key});

  @override
  State<PasarMalamObserverDemoPage> createState() => _PasarMalamObserverDemoPageState();
}

class _PasarMalamObserverDemoPageState extends State<PasarMalamObserverDemoPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final MotionPathSpawnController _story;
  late final MotionPathSpawnController _bounce;
  late final AnimationController _clock;
  late final MotionPathScrollDriver _driver;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _story = MotionPathSpawnController(parent: MotionPathTrackRuntime('pasar-malam-observer-story'));
    for (final MotionPathTrackRuntime track in pasarMalamStoryTracks()) {
      if (!track.id.endsWith('-wrap')) _story.spawn(track);
    }
    _bounce = MotionPathSpawnController(parent: MotionPathTrackRuntime('lantern-bounce-observer'));
    for (final MotionPathTrackRuntime track in pasarMalamBounceTracks()) {
      _bounce.spawn(track);
    }
    _clock = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(_onClock);
    _driver = MotionPathScrollDriver(
      binding: const MotionPathScrollBinding(end: pasarMalamObserverScrollSpan),
      onProgress: _onScroll,
    );
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      _driver.attach(_scroll);
      _clock.repeat(reverse: true);
    });
  }

  void _onScroll(double progress) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _story.advanceTo(progress);
    });
  }

  void _onClock() => _bounce.advanceTo(_clock.value * pasarMalamBounceDuration);

  @override
  void dispose() {
    _driver.dispose();
    _clock.dispose();
    _story.dispose();
    _bounce.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080A1A),
        appBar: AppBar(
          title: const Text('MotionPath Pasar Malam Observer'),
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
              _ObserverBackdrop(progress: _progress),
              Center(
                child: SizedBox(
                  width: pasarMalamObserverStageSize.width,
                  height: pasarMalamObserverStageSize.height,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      MotionPathSpawnView(
                        alignment: Alignment.center,
                        controller: _story,
                        itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) => _ObserverStoryItem(id: instance.id),
                      ),
                      MotionPathSpawnView(
                        alignment: Alignment.center,
                        controller: _bounce,
                        itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) => _ObserverLantern(id: instance.id),
                      ),
                    ],
                  ),
                ),
              ),
              ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  SizedBox(height: constraints.maxHeight + pasarMalamObserverScrollSpan),
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Text('Observer-driven bounce: the lantern loop owns its clock, not scroll.', style: TextStyle(color: Colors.white54, fontSize: 18)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ObserverBackdrop extends StatelessWidget {
  const _ObserverBackdrop({required this.progress});
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
            const Color(0xFF07162B),
            const Color(0xFF050611),
          ],
        ),
      ),
      child: Center(child: Text('OBSERVER FRAME ${frame.toString().padLeft(4, '0')}', style: const TextStyle(color: Colors.white24, letterSpacing: 3))),
    );
  }
}

class _ObserverStoryItem extends StatelessWidget {
  const _ObserverStoryItem({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case 'hero-title':
        return const Text('Pasar Malam', style: TextStyle(fontSize: 62, fontWeight: FontWeight.w900));
      case 'card-left':
        return const _ObserverCard(label: 'STREET FLAVORS', title: 'Nostalgic Tastes', color: Color(0xFFFF0080));
      case 'card-right':
        return const _ObserverCard(label: 'NIGHT VIBES', title: 'Carnival Thrills', color: Color(0xFF00E5FF));
      case 'stats-card':
        return const _ObserverCard(label: 'OPEN', title: '192+ stalls / 10K visitors', color: Color(0xFFFF82C8));
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ObserverCard extends StatelessWidget {
  const _ObserverCard({required this.label, required this.title, required this.color});
  final String label;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 240,
        height: 118,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xCC14152F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(label, style: TextStyle(color: color, letterSpacing: 1.5, fontSize: 11)),
              const Spacer(),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}

class _ObserverLantern extends StatelessWidget {
  const _ObserverLantern({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final Color color = id == 'lantern-1' ? const Color(0xFFFF416C) : id == 'lantern-2' ? const Color(0xFFFFD166) : const Color(0xFFFF82C8);
    return Container(width: 54, height: 78, decoration: BoxDecoration(color: color.withValues(alpha: 0.82), borderRadius: BorderRadius.circular(28), boxShadow: <BoxShadow>[BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 24)]), child: const Center(child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 24))));
  }
}
