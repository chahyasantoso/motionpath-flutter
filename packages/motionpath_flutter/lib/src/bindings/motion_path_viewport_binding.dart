import 'package:flutter/widgets.dart';
import 'package:motionpath_core/motionpath_core.dart';

/// Resolved viewport geometry for a single sampled scroll offset.
///
/// This is a plain value so a host can lay out pinned or scroll-driven content
/// without the engine ever learning about viewports.
@immutable
class MotionPathViewportSample {
  /// Creates a sample.
  const MotionPathViewportSample({
    required this.scrollPixels,
    required this.localOffset,
    required this.progress,
    required this.visible,
    required this.pinned,
    required this.paintOffset,
  });

  /// Scroll offset this sample was taken at.
  final double scrollPixels;

  /// Unpinned item position relative to the viewport's leading edge.
  final double localOffset;

  /// Normalized progress across the authored `[start, end]` window.
  final double progress;

  /// Whether the host should paint the item.
  ///
  /// A pinned item stays visible even after [localOffset] walks past the
  /// viewport: the host is holding it at the leading edge, so the unpinned
  /// intersection test no longer describes what is on screen.
  final bool visible;

  /// Whether the item is held at the viewport's leading edge.
  final bool pinned;

  /// Offset the host should paint at, relative to the viewport leading edge.
  final double paintOffset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MotionPathViewportSample &&
          other.scrollPixels == scrollPixels &&
          other.localOffset == localOffset &&
          other.progress == progress &&
          other.visible == visible &&
          other.pinned == pinned &&
          other.paintOffset == paintOffset;

  @override
  int get hashCode => Object.hash(
    scrollPixels,
    localOffset,
    progress,
    visible,
    pinned,
    paintOffset,
  );

  @override
  String toString() =>
      'MotionPathViewportSample(scrollPixels: $scrollPixels, '
      'localOffset: $localOffset, progress: $progress, '
      'visible: $visible, pinned: $pinned, paintOffset: $paintOffset)';
}

/// Receives every sample the binding publishes.
typedef MotionPathViewportListener =
    void Function(MotionPathViewportSample sample);

/// Samples a scroll position into viewport geometry and seeks a motion.
///
/// The binding never starts a clock. It converts an offset into a
/// [MotionPathViewportSample], seeks [motion] to the sampled progress, and
/// reports authored window crossings. Disposal is terminal.
class MotionPathViewportBinding {
  /// Creates a binding over the authored `[start, end]` scroll window.
  MotionPathViewportBinding({
    required this.motion,
    required this.itemStart,
    required this.itemExtent,
    required this.viewportExtent,
    this.start = 0,
    this.end = 1,
    this.pin = false,
    this.onSample,
    this.onToggle,
  }) {
    MotionPathToggleStateMachine.validateWindow(start, end);
  }

  /// Motion seeked from the sampled progress.
  final MotionPathMotionRuntime motion;

  /// Item position in scroll content coordinates.
  final double itemStart;

  /// Item extent along the scroll axis.
  final double itemExtent;

  /// Viewport extent along the scroll axis.
  final double viewportExtent;

  /// Offset where progress reaches zero.
  final double start;

  /// Offset where progress reaches one.
  final double end;

  /// Whether the item pins at the leading edge inside the window.
  final bool pin;

  /// Called once per published sample.
  final void Function(MotionPathViewportSample sample)? onSample;

  /// Called once per authored window crossing, in travel order.
  final void Function(MotionPathToggleAction action)? onToggle;

  final MotionPathToggleStateMachine _toggles = MotionPathToggleStateMachine();
  final List<MotionPathViewportListener> _listeners =
      <MotionPathViewportListener>[];
  ScrollPosition? _position;
  bool _disposed = false;
  MotionPathViewportSample _sample = _zeroSample;

  static const MotionPathViewportSample _zeroSample =
      MotionPathViewportSample(
        scrollPixels: 0,
        localOffset: 0,
        progress: 0,
        visible: false,
        pinned: false,
        paintOffset: 0,
      );

  /// Whether a scroll position is currently driving this binding.
  bool get isAttached => _position != null;

  /// Whether the binding has been disposed.
  bool get isDisposed => _disposed;

  /// Most recent sample, or the zero sample while detached.
  MotionPathViewportSample get sample => _sample;

  /// Current zone against the authored window, or null while unseeded.
  MotionPathTriggerZone? get zone => _toggles.zone;

  /// Registers [listener] for every published sample.
  void addListener(MotionPathViewportListener listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  /// Removes a previously registered [listener].
  void removeListener(MotionPathViewportListener listener) {
    _listeners.remove(listener);
  }

  /// Resolves viewport geometry for [scrollPixels] without any host state.
  static MotionPathViewportSample sampleAt({
    required double scrollPixels,
    required double itemStart,
    required double itemExtent,
    required double viewportExtent,
    double start = 0,
    double end = 1,
    bool pin = false,
  }) {
    MotionPathToggleStateMachine.validateWindow(start, end);
    final double span = end - start;
    final double progress = span <= 0
        ? (scrollPixels >= end ? 1 : 0)
        : ((scrollPixels - start) / span).clamp(0.0, 1.0).toDouble();
    final double localOffset = itemStart - scrollPixels;
    final bool pinned = pin && progress > 0 && progress < 1;
    final bool intersects =
        localOffset < viewportExtent && localOffset + itemExtent > 0;
    // A pinned item is parked at the leading edge, so its unpinned local
    // offset walks off screen while the host is still painting it. Judging
    // visibility on intersection alone dropped a section mid-pin.
    final bool visible =
        itemExtent > 0 && viewportExtent > 0 && (pinned || intersects);
    final double paintOffset = pinned
        ? 0
        : localOffset.clamp(-itemExtent, viewportExtent).toDouble();
    return MotionPathViewportSample(
      scrollPixels: scrollPixels,
      localOffset: localOffset,
      progress: progress,
      visible: visible,
      pinned: pinned,
      paintOffset: paintOffset,
    );
  }

  /// Attaches to [position] and seeds from its current offset.
  void attach(ScrollPosition position) {
    if (_disposed) return;
    detach();
    _position = position;
    position.addListener(_onScroll);
    _onScroll();
  }

  /// Detaches from any scroll position and resets sampled state.
  void detach() {
    _position?.removeListener(_onScroll);
    _position = null;
    _sample = _zeroSample;
    _toggles.reset();
  }

  /// Samples [scrollPixels], seeks the motion, and publishes the result.
  void sampleFromOffset(double scrollPixels) {
    if (_disposed) return;
    _sample = sampleAt(
      scrollPixels: scrollPixels,
      itemStart: itemStart,
      itemExtent: itemExtent,
      viewportExtent: viewportExtent,
      start: start,
      end: end,
      pin: pin,
    );
    motion.seek(_sample.progress);
    final List<MotionPathToggleAction> actions = _toggles.updateForValue(
      value: scrollPixels,
      start: start,
      end: end,
    );
    final void Function(MotionPathToggleAction action)? toggle = onToggle;
    if (toggle != null) {
      for (final MotionPathToggleAction action in actions) {
        toggle(action);
      }
    }
    onSample?.call(_sample);
    for (final MotionPathViewportListener listener
        in List<MotionPathViewportListener>.of(_listeners)) {
      listener(_sample);
    }
  }

  void _onScroll() {
    if (_disposed) return;
    final ScrollPosition? position = _position;
    if (position != null) sampleFromOffset(position.pixels);
  }

  /// Releases the binding for good. Disposal is idempotent and terminal.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    detach();
    _listeners.clear();
  }
}
