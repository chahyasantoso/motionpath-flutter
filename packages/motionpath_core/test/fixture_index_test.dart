import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'support/fixture_support.dart';

const String _fixtureDirectory = 'test/fixtures';
const String _indexFile = 'motionpath_fixture_index.json';

List<Map<String, Object?>> _entries(Map<String, Object?> index) => <Map<String, Object?>>[
      for (final Object? raw in index['fixtures']! as List<Object?>)
        raw! as Map<String, Object?>,
    ];

List<String> _jsonFixtureFiles() => <String>[
      for (final FileSystemEntity entity in Directory(_fixtureDirectory).listSync())
        if (entity is File && entity.path.endsWith('.json'))
          entity.path.substring(entity.path.lastIndexOf('/') + 1),
    ];

void main() {
  final Map<String, Object?> index = readFixture(_indexFile);
  final List<Map<String, Object?>> entries = _entries(index);

  test('fixture index has a stable schema', () {
    expect(index['format'], 'motionpath-fixture-index');
    expect(index['formatVersion'], 1);
    expect(entries, isNotEmpty);
    expect(entries.map((Map<String, Object?> entry) => entry['file']).toSet(), hasLength(entries.length));
    expect(entries.map((Map<String, Object?> entry) => entry['test']).toSet(), hasLength(entries.length));
  });

  test('every JSON fixture is indexed exactly once', () {
    final Set<String> indexed = entries
        .map((Map<String, Object?> entry) => entry['file']! as String)
        .toSet();
    expect(indexed, _jsonFixtureFiles().toSet());
    expect(indexed, isNot(contains(_indexFile)));
  });

  for (final Map<String, Object?> entry in entries) {
    final String file = entry['file']! as String;
    final String testFile = entry['test']! as String;
    test('$file has valid metadata and a harness', () {
      final Map<String, Object?> fixture = readFixture(file);
      expect(File('test/$testFile').existsSync(), isTrue);
      expect(fixture['format'], isA<String>());
      expect(fixture['formatVersion'], 1);
      expect(fixture['cases'], isA<Map<String, Object?>>());
      final Object? tolerance = entry['tolerance'];
      expect(tolerance == null || tolerance is num, isTrue);
      final List<Object?> cases = entry['cases']! as List<Object?>;
      final Map<String, Object?> actualCases = fixture['cases']! as Map<String, Object?>;
      expect(cases, isNotEmpty);
      for (final Object? caseName in cases) {
        expect(caseName, isA<String>());
        expect(actualCases.containsKey(caseName), isTrue, reason: '$file is missing case $caseName');
      }
    });
  }

  test('fixture index is valid JSON', () {
    expect(() => jsonDecode(File('$_fixtureDirectory/$_indexFile').readAsStringSync()), returnsNormally);
  });
}
