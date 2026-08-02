import 'dart:convert';
import 'dart:io';

/// Loads one versioned JS parity fixture from the package test directory.
///
/// Keeping path resolution and JSON decoding here prevents each parity harness
/// from growing a subtly different loader.
Map<String, Object?> readFixture(String filename) => jsonDecode(
      File('test/fixtures/$filename').readAsStringSync(),
    ) as Map<String, Object?>;
