import 'package:flutter/material.dart';

import 'burst_demo.dart';
import 'carousel_demo.dart';
import 'helix_demo.dart';
import 'hooks_demo.dart';
import 'motorcycle_demo.dart';
import 'pasar_malam_demo.dart';
import 'pasar_malam_observer_demo.dart';
import 'tower_defense_demo.dart';
import 'walker_demo.dart';

void main() => runApp(const MotionPathExampleApp());

class MotionPathExampleApp extends StatelessWidget {
  const MotionPathExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const DemoLauncherPage(),
      );
}

class DemoLauncherPage extends StatefulWidget {
  const DemoLauncherPage({super.key});

  @override
  State<DemoLauncherPage> createState() => _DemoLauncherPageState();
}

class _DemoLauncherPageState extends State<DemoLauncherPage> {
  int _selectedIndex = 0;

  static const List<String> _titles = <String>[
    'Walker',
    'Burst',
    'Motorcycle',
    'Pasar Malam',
    'Pasar Malam Observer',
    'Tower Defense',
    'Hooks Demo',
    'Helix',
    'Carousel',
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.directions_walk,
    Icons.blur_on,
    Icons.two_wheeler,
    Icons.nightlight,
    Icons.remove_red_eye,
    Icons.shield,
    Icons.auto_awesome,
    Icons.all_inclusive,
    Icons.view_carousel,
  ];

  static const List<String> _descriptions = <String>[
    'FK walking graph',
    'Scroll-driven burst',
    'Scroll-driven ride',
    'Scroll-driven night market',
    'Observer-driven lantern loop',
    'Interactive tower defense',
    'Direct patch consumption',
    'Depth and Matrix4',
    'Interactive path cards',
  ];

  Widget _selectedDemo() {
    switch (_selectedIndex) {
      case 0: return const WalkerDemoPage();
      case 1: return const BurstDemoPage();
      case 2: return const MotorcycleDemoPage();
      case 3: return const PasarMalamDemoPage();
      case 4: return const PasarMalamObserverDemoPage();
      case 5: return const TowerDefenseDemoPage();
      case 6: return const HooksDemoPage();
      case 7: return const HelixDemoPage();
      case 8: return const CarouselDemoPage();
      default: return const WalkerDemoPage();
    }
  }

  void _selectDemo(int index) {
    Navigator.of(context).pop();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('MotionPath demos'),
          actions: <Widget>[
            Builder(
              builder: (BuildContext context) => IconButton(
                tooltip: 'Choose demo',
                icon: const Icon(Icons.apps),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Text(
                    'Choose a demo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                for (int index = 0; index < _titles.length; index++)
                  ListTile(
                    selected: index == _selectedIndex,
                    leading: Icon(_icons[index]),
                    title: Text(_titles[index]),
                    subtitle: Text(_descriptions[index]),
                    onTap: () => _selectDemo(index),
                  ),
              ],
            ),
          ),
        ),
        body: _selectedDemo(),
      );
}
