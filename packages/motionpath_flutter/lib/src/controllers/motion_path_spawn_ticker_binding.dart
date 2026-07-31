import '../ticker/motion_path_ticker_driver.dart';
import 'motion_path_spawn_controller.dart';

/// Drives a spawn surface from an existing [MotionPathTickerDriver].
///
/// This binding deliberately does not own a ticker. Engine motions and dynamic
/// child tracks advance from the same delta, in the same frame, with one shared
/// clock. The binding is just lifecycle glue between the scheduler and the
/// spawn controller.
class MotionPathSpawnTickerBinding {
  /// Creates and wires a binding.
  MotionPathSpawnTickerBinding({required this.driver, required this.controller})
    : _removeListener = driver.addTickListener(controller.advanceBy);

  /// Shared engine ticker.
  final MotionPathTickerDriver driver;

  /// Spawn surface to advance.
  final MotionPathSpawnController controller;

  final void Function() _removeListener;
  bool _disposed = false;

  /// Whether this binding is still connected.
  bool get isAttached => !_disposed;

  /// Disconnects without stopping the shared ticker.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _removeListener();
  }
}
