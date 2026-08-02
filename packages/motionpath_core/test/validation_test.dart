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

  test('rejects repeat, delay, and duration on a scroll-scrub trigger', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(<String, Object?>{'schemaVersion': 4, 'motions': <Object?>[<String, Object?>{'id': 'scrubbed', 'trigger': <String, Object?>{'type': 'scroll', 'scrub': true, 'repeat': 2, 'delay': 1}, 'tracks': <Object?>[<String, Object?>{'id': 'a', 'duration': 1, 'keyframes': <String, Object?>{'opacity': <String, Object?>{'stops': <Object?>[<String, Object?>{'p': 0, 'v': 0}, <String, Object?>{'p': 1, 'v': 1}]}}}]}]});
    expect(_codes(diagnostics).where((String code) => code == 'trigger-shape'), hasLength(3));
  });

  test('requires scrub on a scroll trigger', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(<String, Object?>{'schemaVersion': 4, 'motions': <Object?>[<String, Object?>{'id': 'scrolled', 'trigger': <String, Object?>{'type': 'scroll'}, 'tracks': <Object?>[<String, Object?>{'id': 'a'}]}]});
    expect(diagnostics.map((MotionPathDiagnostic d) => d.path), contains('motions[0].trigger.scrub'));
  });

  test('reports stop count, shape, and sequence problems', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(<String, Object?>{'schemaVersion': 4, 'motions': <Object?>[<String, Object?>{'id': 'stops', 'trigger': <String, Object?>{'type': 'time'}, 'tracks': <Object?>[<String, Object?>{'id': 'single', 'keyframes': <String, Object?>{'opacity': <String, Object?>{'stops': <Object?>[<String, Object?>{'p': 0.5, 'v': 1}]}}}, <String, Object?>{'id': 'backwards', 'keyframes': <String, Object?>{'x': <String, Object?>{'stops': <Object?>[<String, Object?>{'p': 0, 'v': 0}, <String, Object?>{'p': 0.8, 'v': 5}, <String, Object?>{'p': 0.4, 'v': 9}, <String, Object?>{'p': 1}]}}}]}]});
    final List<String> codes = _codes(diagnostics);
    expect(codes, contains('stop-count'));
    expect(codes, contains('stop-shape'));
    expect(codes, contains('stop-sequence'));
    expect(diagnostics.any((MotionPathDiagnostic d) => d.severity == MotionPathSeverity.warning), isTrue);
  });

  test('a warning alone never blocks loading', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(_project(<String, Object?>{'opacity': <String, Object?>{'stops': <Object?>[<String, Object?>{'p': 0.2, 'v': 0}, <String, Object?>{'p': 0.9, 'v': 1}]}}));
    expect(diagnostics, isNotEmpty);
    expect(hasFatalErrors(diagnostics), isFalse);
  });

  test('rejects malformed path payloads before composition', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(_project(<String, Object?>{'path': <String, Object?>{'points': <Object?>[<String, Object?>{'x': 0, 'y': 0}, <String, Object?>{'x': 'bad', 'y': 20, 'ctrlY': 'bad'}], 'stops': <Object?>[<String, Object?>{'p': 0, 'v': 0}, <String, Object?>{'p': 1, 'v': 1}]}}));
    expect(_codes(diagnostics), contains('path-shape'));
    expect(diagnostics.any((MotionPathDiagnostic d) => d.path.endsWith('points[1].x')), isTrue);
  });

  test('rejects empty and non-string image frames before composition', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(_project(<String, Object?>{'imageSequence': <String, Object?>{'frames': <Object?>['ok.webp', '', 42], 'stops': <Object?>[<String, Object?>{'p': 0, 'v': 0}, <String, Object?>{'p': 1, 'v': 2}]}}));
    expect(_codes(diagnostics).where((String code) => code == 'image-sequence-shape'), hasLength(2));
  });

  test('warns on first-point controls without blocking the project', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(_project(<String, Object?>{'path': <String, Object?>{'points': <Object?>[<String, Object?>{'x': 0, 'y': 0, 'ctrlX': 1, 'ctrlY': 1}, <String, Object?>{'x': 10, 'y': 10}], 'stops': <Object?>[<String, Object?>{'p': 0, 'v': 0}, <String, Object?>{'p': 1, 'v': 1}]}}));
    expect(diagnostics.any((MotionPathDiagnostic d) => d.severity == MotionPathSeverity.warning && d.code == 'path-shape'), isTrue);
    expect(hasFatalErrors(diagnostics), isFalse);
  });

  test('rejects path stop values outside normalized progress', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(_project(<String, Object?>{'path': <String, Object?>{'points': <Object?>[<String, Object?>{'x': 0, 'y': 0}, <String, Object?>{'x': 10, 'y': 10}], 'stops': <Object?>[<String, Object?>{'p': 0, 'v': -0.1}, <String, Object?>{'p': 1, 'v': 1.5}]}}));
    final List<MotionPathDiagnostic> errors = diagnostics.where((MotionPathDiagnostic d) => d.isFatal && d.code == 'path-shape').toList(growable: false);
    expect(errors, hasLength(2));
    expect(errors.first.path, endsWith('stops[0].v'));
    expect(errors.last.path, endsWith('stops[1].v'));
  });
}
