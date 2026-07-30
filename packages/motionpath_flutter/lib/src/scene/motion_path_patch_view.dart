import 'package:flutter/widgets.dart';

import '../painters/motion_path_patch_painter.dart';
import 'motion_path_patch_source.dart';

/// Paints one track's composed patch and repaints when the patch changes.
///
/// This is the smallest honest scene widget: one track, one diagnostic square.
/// It exists to prove the tick to paint path end to end before the Walker
/// renderer lands.
class MotionPathPatchView extends StatelessWidget {
  /// Creates a view bound to [trackId] inside [source].
  const MotionPathPatchView({
    required this.source,
    required this.trackId,
    this.size = const Size(200, 200),
    this.extent = 80,
    super.key,
  });

  /// Publishes composed patches.
  final MotionPathPatchSource source;

  /// Track whose patch this view paints.
  final String trackId;

  /// Canvas size in logical pixels.
  final Size size;

  /// Side length of the diagnostic square.
  final double extent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: source,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          size: size,
          painter: MotionPathPatchPainter(patch: source.patchFor(trackId), extent: extent),
        );
      },
    );
  }
}
