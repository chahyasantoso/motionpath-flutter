import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

import 'walker_scene.dart';

class WalkerDemoPage extends StatefulWidget {
  const WalkerDemoPage({super.key});

  @override
  State<WalkerDemoPage> createState() => _WalkerDemoPageState();
}

class _WalkerDemoPageState extends State<WalkerDemoPage> {
  final ScrollController _scroll = ScrollController();
  late final MotionPathEngine _engine;
  late final MotionPathMotionRuntime _motion;
  late final MotionPathPatchSource _source;

  @override
  void initState() {
    super.initState();
    final List<MotionPathTrackRuntime> tracks = walkerSceneTracks();
    final MotionPathTrackRuntime pelvis = tracks.first;
    _engine = MotionPathEngine();
    _motion = MotionPathMotionRuntime(
      'walker',
      tracks: <MotionPathTrackRuntime>[pelvis],
    );
    _source = MotionPathPatchSource()..bind(_motion);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final double progress = (_scroll.offset / 900).clamp(0.0, 1.0).toDouble();
    _motion.seek(progress);
    _source.publish(_motion.composeGraph());
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _source.dispose();
    _motion.dispose();
    _engine.destroy();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0B0D16),
        appBar: AppBar(title: const Text('MotionPath Walker')),
        body: ListView(
          controller: _scroll,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'FK walking is authored as local bone angles and composed into world patches.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(
              height: 360,
              child: MotionPathWalkerScene(
                source: _source,
                size: const Size(760, 300),
              ),
            ),
            const SizedBox(height: 900),
          ],
        ),
      );
}
