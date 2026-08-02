import 'package:flutter/material.dart';
import 'package:motionpath_core/motionpath_core.dart';
import 'package:motionpath_flutter/motionpath_flutter.dart';

import 'helix_scene.dart';

class HelixDemoPage extends StatefulWidget {
  const HelixDemoPage({super.key});

  @override
  State<HelixDemoPage> createState() => _HelixDemoPageState();
}

class _HelixDemoPageState extends State<HelixDemoPage> {
  late final MotionPathSpawnController _spawns;

  @override
  void initState() {
    super.initState();
    final MotionPathTrackRuntime parent = MotionPathTrackRuntime('helix');
    _spawns = MotionPathSpawnController(parent: parent);
    for (final MotionPathTrackRuntime track in helixSceneTracks()) {
      _spawns.spawn(track);
    }
  }

  @override
  void dispose() {
    _spawns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF070A12),
        appBar: AppBar(
          title: const Text('MotionPath Helix'),
          actions: const <Widget>[Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: Text('z-depth + Matrix4')),
          )],
        ),
        body: Center(
          child: SizedBox(
            width: 620,
            height: 520,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                const Positioned.fill(child: _HelixBackdrop()),
                MotionPathSpawnView(
                  alignment: Alignment.center,
                  controller: _spawns,
                  itemBuilder: (BuildContext context, MotionPathSpawnInstance instance) {
                    final int index = int.parse(instance.id.split('-').last);
                    return _HelixCard(index: index);
                  },
                ),
              ],
            ),
          ),
        ),
      );
}

class _HelixCard extends StatelessWidget {
  const _HelixCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        height: 190,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFF263A78), const Color(0xFF79E6D0), index / 4),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white24),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
            ],
          ),
          child: Center(
            child: Text(
              'HELIX ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
            ),
          ),
        ),
      );
}

class _HelixBackdrop extends StatelessWidget {
  const _HelixBackdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const RadialGradient(
            colors: <Color>[Color(0x442C4D99), Color(0x00070A12)],
          ),
          border: Border.all(color: Colors.white10),
        ),
      );
}
