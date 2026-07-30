import 'package:flutter_test/flutter_test.dart';
import 'package:motionpath_core/motionpath_core.dart';

import '../lib/spiral_project.dart';

void main() {
  test('spiral ball is authored and validated as a v4 project', () {
    final MotionPathProject project =
        MotionPathProject.fromJson(spiralBallProjectJson);
    final MotionPathTrack track = project.motions.single.tracks.single;

    expect(project.schemaVersion, 4);
    expect(track.duration, 12);
    expect(track.keyframes, containsPair('path', isNotNull));
    expect(track.keyframes, containsPair('opacity', isNotNull));
    expect(track.keyframes, containsPair('--ball-size', isNotNull));
  });
}
