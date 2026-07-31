import 'dart:convert';
import 'dart:io';

import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'canonical v4 fixture has no fatal diagnostics and preserves coverage',
    () {
      final String source = File(
        '../../fixtures/v4-project.json',
      ).readAsStringSync();
      final Map<String, Object?> json =
          jsonDecode(source) as Map<String, Object?>;
      final List<MotionPathDiagnostic> diagnostics = validateProject(json);

      expect(diagnostics.where((MotionPathDiagnostic d) => d.isFatal), isEmpty);
      final MotionPathProject project = MotionPathProject.fromJson(json);
      expect(project.schemaVersion, 4);
      expect(project.projectId, 'integration-fixture');
      expect(project.templates.single['templateId'], 'fade-pop');
      expect(
        project.motions.map((MotionPathMotion motion) => motion.id),
        <String>[
          'scroll-scrub',
          'time-loop',
          'time-paused',
          'manual-scrubber',
          'sequence',
        ],
      );
      expect(project.motions[1].tracks[0].duration, 0.6);
      expect(
        project.motions[1].tracks[2].keyframes.containsKey('--card-size'),
        isTrue,
      );
      expect(project.tracks.single.id, 'ball-exit-track');
    },
  );
}
