import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Turns Flutter scroll offsets into normalized MotionPath progress.
class MotionPathScrollDriver {
  MotionPathScrollDriver({required this.binding, required this.onProgress});

  final MotionPathScrollBinding binding;
  final void Function(double progress) onProgress;
  ScrollController? _controller;
  bool _disposed = false;

  ScrollController? get controller => _controller;

  void attach(ScrollController controller) {
    if (_disposed) return;
    detach();
    _controller = controller;
    controller.addListener(_handleScroll);
    _handleScroll();
  }

  void detach() {
    _controller?.removeListener(_handleScroll);
    _controller = null;
  }

  void _handleScroll() {
    final ScrollController? current = _controller;
    if (_disposed || current == null || !current.hasClients) return;
    onProgress(binding.progressFor(current.offset));
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    detach();
  }
}
