import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

import 'support/fixture_support.dart';

// Every expected code, severity, JSON path, and message fragment lives in the
// versioned fixture. This harness only hydrates non-finite sentinels, runs the
// validator, and matches diagnostics one-for-one, so no validation semantics
// are encoded here.
const Map<String, double> _nonFinite = <String, double>{
  '@Infinity': double.infinity,
  '@-Infinity': double.negativeInfinity,
  '@NaN': double.nan,
};

Object? _hydrate(Object? value) {
  if (value is String) return _nonFinite[value] ?? value;
  if (value is List<Object?>) return <Object?>[for (final Object? entry in value) _hydrate(entry)];
  if (value is Map<String, Object?>) {
    return <String, Object?>{
      for (final MapEntry<String, Object?> entry in value.entries) entry.key: _hydrate(entry.value),
    };
  }
  return value;
}

Map<String, Object?> _project(Map<String, Object?> testCase) => _hydrate(testCase['project'])! as Map<String, Object?>;

MotionPathSeverity _severity(Object? value) {
  if (value == 'error') return MotionPathSeverity.error;
  if (value == 'warning') return MotionPathSeverity.warning;
  throw ArgumentError.value(value, 'severity', 'Unknown diagnostic severity in fixture.');
}

List<Map<String, Object?>> _expectations(Map<String, Object?> testCase) => <Map<String, Object?>>[
      for (final Object? raw in testCase['expect']! as List<Object?>) raw! as Map<String, Object?>,
    ];

void main() {
  final Map<String, Object?> fixture = readFixture('motionpath_diagnostics_fixtures.json');
  final Map<String, Object?> cases = fixture['cases']! as Map<String, Object?>;

  for (final MapEntry<String, Object?> entry in cases.entries) {
    final Map<String, Object?> testCase = entry.value! as Map<String, Object?>;

    test('${entry.key} produces exactly the fixture diagnostics', () {
      final List<MotionPathDiagnostic> remaining = List<MotionPathDiagnostic>.of(
        validateProject(_project(testCase)),
      );
      for (final Map<String, Object?> want in _expectations(testCase)) {
        final String path = want['path']! as String;
        final String code = want['code']! as String;
        final MotionPathSeverity severity = _severity(want['severity']);
        final Object? fragment = want['messageContains'];
        final int index = remaining.indexWhere(
          (MotionPathDiagnostic diagnostic) =>
              diagnostic.path == path &&
              diagnostic.code == code &&
              diagnostic.severity == severity &&
              (fragment is! String || diagnostic.message.contains(fragment)),
        );
        expect(index, isNonNegative, reason: 'missing ${severity.name} $code at $path');
        remaining.removeAt(index);
      }
      expect(remaining, isEmpty, reason: 'unexpected diagnostics: ${remaining.join(' | ')}');
    });

    test('${entry.key} fatality gates the trust boundary', () {
      final Map<String, Object?> project = _project(testCase);
      final bool fatal = testCase['fatal']! as bool;
      expect(hasFatalErrors(validateProject(project)), fatal);
      if (fatal) {
        expect(() => MotionPathProject.fromJson(project), throwsA(isA<MotionPathValidationException>()));
      } else {
        expect(MotionPathProject.fromJson(project).schemaVersion, 4);
      }
    });
  }

  test('every documented diagnostic code appears somewhere in the matrix', () {
    final Set<String> covered = <String>{
      for (final Object? raw in cases.values)
        for (final Map<String, Object?> want in _expectations(raw! as Map<String, Object?>)) want['code']! as String,
    };
    expect(covered, containsAll(fixture['codes']! as List<Object?>));
  });
}
