import 'package:flutter/material.dart';

import 'helix_demo.dart';

void main() => runApp(const MotionPathExampleApp());

class MotionPathExampleApp extends StatelessWidget {
  const MotionPathExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const HelixDemoPage(),
      );
}
