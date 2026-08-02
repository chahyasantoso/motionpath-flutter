import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

List<String> _codes(List<MotionPathDiagnostic> diagnostics) => diagnostics.map((MotionPathDiagnostic d) => d.code).toList(growable: false);
Map<String, Object?> _project(Map<String, Object?> keyframes) => <String, Object?>{'schemaVersion': 4, 'motions': <Object?>[<String, Object?>{'id': 'scene', 'trigger': <String, Object?>{'type': 'time'}, 'tracks': <Object?>[<String, Object?>{'id': 'track', 'keyframes': keyframes}]}]};

void main() {
  test('rejects path combined with explicit x', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(_project(<String, Object?>{
      'path': <String, Object?>{'points': <Object?>[<String, Object?>{'x': 0, 'y': 0}, <String, Object?>{'x': 10, 'y': 10}], 'stops': <Object?>[<String, Object?>{'p': 0, 'v': 0}, <String, Object?>{'p': 1, 'v': 1}]},
      'x': <String, Object?>{'stops': <Object?>[<String, Object?>{'p': 0, 'v': 0}, <String, Object?>{'p': 1, 'v': 1}]},
    }));
    expect(_codes(diagnostics), contains('path-xy-exclusivity'));
    expect(diagnostics.singleWhere((MotionPathDiagnostic d) => d.code == 'path-xy-exclusivity').path, endsWith('.keyframes'));
  });
}
