import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

import 'burst_scene.dart';

/// Scroll runway, in logical pixels, mapped onto the burst timeline.
///
/// This is host chrome, not authored motion: the scene contract owns every
/// keyframe and the runway only decides how much scrolling spends it.
const double burstScrollSpan = 900;

/// Stage the burst cards are composed into.
const Size burstStageSize = Size(620, 520);

class BurstDemoPage extends StatefulWidget {
  const BurstDemoPage({super.key});

  @override
  State<BurstDemoPage> createState() => _BurstDemoPageState();
}

class _BurstDemoPageState extends State<BurstDemoPage> {
  final ScrollController _scroll = ScrollController();
  late final MotionPathSpawnController _spawns;
  late final MotionPathScrollDriver _driver;

  @override
  void initState() {
    super.initState();
    final MotionPathTrackRuntime parent = MotionPathTrackRuntime('burst');
    _spawns = MotionPathSpawnController(parent: parent);
    for (final MotionPathTrackRuntime track in burstSceneTracks()) {
      _spawns.spawn(track);
    }
    _driver = MotionPathScrollDriver(
      binding: const MotionPathScrollBinding(end: burstScrollSpan),
      onProgress: _onProgress,
    );
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _driver.attach(_scroll);
    });
  }

  /// Every card shares the parent timeline, so normalized scroll progress is
  /// the playhead. Per-card windows live in the authored `end` boundaries.
  void _onProgress(double progress) => _spawns.advanceTo(progress);

  @override
  void dispose() {
    _driver.dispose();
    _spawns.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF120A14),
        appBar: AppBar(
          title: const Text('MotionPath Burst'),
          actions: const <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: Text('scroll-driven burst')),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const _BurstBackdrop(),
              Center(
                child: SizedBox(
                  width: burstStageSize.width,
                  height: burstStageSize.height,
                  child: MotionPathSpawnView(
                    alignment: Alignment.center,
                    controller: _spawns,
                    itemBuilder: (
                      BuildContext context,
                      MotionPathSpawnInstance instance,
                    ) =>
                        _BurstItem(id: instance.id),
                  ),
                ),
              ),
              // Transparent runway. The stage stays put while this scrolls, so
              // the whole burst is visible across the authored timeline.
              ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  SizedBox(height: constraints.maxHeight + burstScrollSpan),
                ],
              ),
            ],
          ),
        ),
      );
}

class _BurstItem extends StatelessWidget {
  const _BurstItem({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final int? index = int.tryParse(id.split('-').last);
    if (index == null) return const _BurstCenter();
    return _BurstCard(index: index);
  }
}

class _BurstCard extends StatelessWidget {
  const _BurstCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 112,
        height: 142,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFE4436B),
              const Color(0xFFFFC7A1),
              (index - 1) / 9,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'BERRY $index',
              style: const TextStyle(
                color: Color(0xFF2A0713),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      );
}

class _BurstCenter extends StatelessWidget {
  const _BurstCenter();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 188,
        height: 224,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFFFF3E2), Color(0xFFF7B7CB)],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white38),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'ICE CREAM',
              style: TextStyle(
                color: Color(0xFF2A0713),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
          ),
        ),
      );
}

class _BurstBackdrop extends StatelessWidget {
  const _BurstBackdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: <Color>[Color(0x55A33A63), Color(0x00120A14)],
          ),
        ),
        child: SizedBox.expand(),
      );
}
