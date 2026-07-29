import 'package:test/test.dart';
import 'package:motionpath_core/motionpath_core.dart';

void main() {
  test('parses a valid MotionPath v4 project', () {
    final project = MotionPathProject.fromJson(<String, Object?>{
      'schemaVersion': 4,
      'projectId': 'demo',
      'motions': <Object?>[
        <String, Object?>{'id': 'hero', 'trigger': <String, Object?>{'type': 'manual'}},
      ],
    });
    expect(project.schemaVersion, 4);
    expect(project.motions.single.id, 'hero');
  });

  test('collects schema diagnostics before throwing', () {
    final diagnostics = validateProject(<String, Object?>{
      'schemaVersion': 3,
      'motions': <Object?>[<String, Object?>{'id': '', 'trigger': 'bad'}],
    });
    expect(diagnostics.map((d) => d.code), containsAll(<String>['unsupported', 'required', 'required']));
  });

  test('rejects malformed JSON shape', () {
    expect(() => MotionPathProject.fromJson(<String, Object?>{'schemaVersion': 4}), throwsA(isA<MotionPathValidationException>()));
  });
}
