import 'package:flutter/foundation.dart';

/// Temporary adapter marker until the Ticker-backed driver lands in Phase 4.
class MotionPathFlutterAdapter {
  const MotionPathFlutterAdapter();

  void assertFlutterAvailable() {
    assert(kIsWeb || !kIsWeb);
  }
}
