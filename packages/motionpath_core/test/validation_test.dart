import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

List<String> _codes(List<MotionPathDiagnostic> diagnostics) => diagnostics.map((MotionPathDiagnostic d) => d.code).toList(growable: false);
Map<String, Object?> _project(Map<String, Object?> keyframes) => <String, Object?>{'schemaVersion': 4, 'motions': <Object?>[<String, Object?>{'id': 'scene', 'trigger': <String, Object?>{'type': 'time'}, 'tracks': <Object?>[<String, Object?>{'id': 'track', 'keyframes': keyframes}]}]};

void main() {
  test('rejects image stop values outside frame range', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(_project(<String, Object?>{
      'imageSequence': <String, Object?>{
        'frames': <Object?>['a.webp', 'b.webp'],
        'stops': <Object?>[
          <String, Object?>{'p': 0, 'v': -1},
          <String, Object?>{'p': 1, 'v': 2},
        ],
      },
    }));
    final List<MotionPathDiagnostic> errors = diagnostics.where((MotionPathDiagnostic d) => d.code == 'image-sequence-shape').toList(growable: false);
    expect(errors, hasLength(2));
    expect(errors.first.path, endsWith('stops[0].v'));
    expect(errors.last.path, endsWith('stops[1].v'));
  });

  test('rejects malformed image stop p and v types', () {
    final List<MotionPathDiagnostic> diagnostics = validateProject(_project(<String, Object?>{
      'imageSequence': <String, Object?>{
        'frames': <Object?>['a.webp', 'b.webp'],
        'stops': <Object?>[
          <String, Object?>{'p': 'zero', 'v': 'first'},
          <String, Object?>{'p': 1, 'v': 1},
        ],
      },
    }));
    expect(_codes(diagnostics).where((String code) => code == 'image-sequence-shape'), hasLength(2));
  });
}
