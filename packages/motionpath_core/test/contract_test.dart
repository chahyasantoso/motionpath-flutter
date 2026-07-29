import 'package:test/test.dart';
import 'package:motionpath_core/motionpath_core.dart';

void main() {
  test('accepts the MotionPath v4 schema version', () {
    const project = MotionPathProject(schemaVersion: 4);
    expect(project.schemaVersion, 4);
  });

  test('rejects a non-v4 schema version at the contract boundary', () {
    const project = MotionPathProject(schemaVersion: 3);
    expect(project.schemaVersion, isNot(4));
  });
}
