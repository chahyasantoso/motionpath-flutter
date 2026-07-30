import '../controllers/motion_path_spawn_controller.dart';
import 'motion_path_ticker_driver.dart';

/// Drives a spawn surface from the engine's existing ticker delta.
///
/// This is a subscriber, not a frame source. Disposing it removes only its own
/// listener and leaves the shared ticker available to the engine and painters.
class MotionPathSpawnTickerBinding {
  MotionPathSpawnTickerBinding({required this.driver, required this.controller}) {
    _removeListener = driver.addTickListener(controller.advanceBy);
  }

  final MotionPathTickerDriver driver;
  final MotionPathSpawnController controller;
  late final void Function() _removeListener;
  bool _disposed = false;

  bool get isAttached => !_disposed;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _removeListener();
  }
}
