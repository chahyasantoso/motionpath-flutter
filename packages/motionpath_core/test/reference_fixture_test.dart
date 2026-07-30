import 'dart:convert';
import 'dart:io';

import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

File _fixtureFile() => File('../../fixtures/v4-project.json');

void main() {
  late MotionPathProject project;

  setUpAll(() {
    project = MotionPathProject.fromJsonString(_fixtureFile().readAsStringSync());
  });

  test('canonical reference fixture has no fatal diagnostics', () {
    final Map<String, Object?> json =
        asStringKeyedMap(jsonDecode(_fixtureFile().readAsStringSync()));
    final List<MotionPathDiagnostic> diagnostics = validateProject(json);
    expect(diagnostics.where((MotionPathDiagnostic d) => d.isFatal), isEmpty);
  });

  test('preserves the reference project topology', () {
    expect(project.schemaVersion, 4);
    expect(project.projectId, 'integration-fixture');
    expect(project.perspective, 1200);
    expect(project.templates, hasLength(1));
    expect(project.motions, hasLength(5));
    expect(project.tracks, hasLength(1));
    expect(
      project.motions.map((MotionPathMotion m) => m.id).toList(),
      <String>[
        'scroll-scrub',
        'time-loop',
        'time-paused',
        'manual-scrubber',
        'sequence',
      ],
    );
  });

  test('resolves templates and authored plugin payloads', () {
    final MotionPathMotion loop = project.motionById('time-loop')!;
    expect(loop.stagger, closeTo(0.12, 1e-9));
    expect(loop.tracks[0].duration, closeTo(0.6, 1e-9));
    expect(loop.tracks[0].keyframes, containsPair('opacity', isNotNull));
    expect(loop.tracks[1].duration, closeTo(0.9, 1e-9));
    expect(loop.tracks[2].keyframes, containsPair('--card-size', isNotNull));

    final MotionPathTrack path = project.motions[0].tracks.single;
    expect(path.keyframes, containsPair('path', isNotNull));
    expect(path.keyframes, containsPair('blur', isNotNull));

    final MotionPathTrack sequence = project.motionById('sequence')!.tracks.single;
    expect(sequence.keyframes, containsPair('imageSequence', isNotNull));
  });

  test('mounts the reference manual and paused motions safely', () {
    final MotionPathEngine engine = MotionPathEngine()..loadProject(project);
    final MotionPathMotionRuntime manual = engine.mountMotion('manual-scrubber');
    final MotionPathMotionRuntime paused = engine.mountMotion('time-paused');
    expect(manual.playing, isFalse);
    expect(paused.playing, isFalse);
    manual.seek(0.5);
    final Map<String, Map<String, Object?>> patches = manual.composeGraph();
    expect(patches['needle']?['rotation'], closeTo(0, 1e-9));
    engine.destroy();
  });
}
