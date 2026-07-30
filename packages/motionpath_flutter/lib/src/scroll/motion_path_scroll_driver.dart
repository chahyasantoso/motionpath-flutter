import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Turns Flutter scroll offsets into normalized MotionPath progress.
///
/// The math lives in [MotionPathScrollBinding] inside the pure Dart core, so
/// this class only owns the listener plumbing. For a scrubbed timeline the
/// scroll position IS the clock, which is why nothing here touches a ticker.
class MotionPathScrollDriver {
  /// Creates a driver that reports progress through [onProgress].
  MotionPathScrollDriver({required this.binding, required this.onProgress});

  /// Offset window and scrub smoothing.
  final MotionPathScrollBinding binding;

  /// Called with normalized progress whenever the attached controller moves.
  final void Function(double progress) onProgress;

  ScrollController? _controller;

  /// The currently attached controller, if any.
  ScrollController? get controller => _controller;

  /// Listens to [controller] and reports its current progress immediately.
  void attach(ScrollController controller) {
    detach();
    _controller = controller;
    controller.addListener(_handleScroll);
    _handleScroll();
  }

  /// Stops listening to the attached controller.
  void detach() {
    _controller?.removeListener(_handleScroll);
    _controller = null;
  }

  void _handleScroll() {
    final ScrollController? current = _controller;
    if (current == null || !current.hasClients) return;
    onProgress(binding.progressFor(current.offset));
  }
}
