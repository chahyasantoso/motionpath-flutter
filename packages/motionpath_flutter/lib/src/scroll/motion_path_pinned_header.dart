import 'package:flutter/widgets.dart';

/// Builds pinned content for the current normalized pin progress.
typedef MotionPathPinnedBuilder =
    Widget Function(BuildContext context, double progress);

/// Pins a section at the viewport's leading edge for a fixed scroll distance.
///
/// Pinning is layout, not animation semantics, so it lives in a host widget and
/// the engine never learns about viewports. The section is [extent] tall and
/// stays put while the next [pinExtent] pixels of scroll are consumed;
/// progress walks `0` to `1` across that runway.
///
/// Content returned by [builder] must be aligned to the top of the header: the
/// sliver collapses from `extent + pinExtent` down to [extent] and clips from
/// the bottom, so top-aligned content is what stays visible.
class MotionPathPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  /// Creates a pin delegate over a `[extent, extent + pinExtent]` runway.
  MotionPathPinnedHeaderDelegate({
    required this.extent,
    required this.pinExtent,
    required this.builder,
  }) {
    if (!extent.isFinite || extent <= 0) {
      throw ArgumentError.value(
        extent,
        'extent',
        'must be finite and greater than zero',
      );
    }
    if (!pinExtent.isFinite || pinExtent < 0) {
      throw ArgumentError.value(
        pinExtent,
        'pinExtent',
        'must be finite and non-negative',
      );
    }
  }

  /// Height the section keeps while pinned, in logical pixels.
  final double extent;

  /// Scroll distance consumed while the section stays pinned.
  final double pinExtent;

  /// Builds the pinned content for the current progress.
  final MotionPathPinnedBuilder builder;

  /// Normalizes a sliver [shrinkOffset] against the authored [pinExtent].
  ///
  /// A zero runway is a valid authoring choice for a section that only wants
  /// the pin, so it reports a binary progress instead of dividing by zero.
  static double progressFor({
    required double shrinkOffset,
    required double pinExtent,
  }) {
    if (pinExtent <= 0) return shrinkOffset > 0 ? 1 : 0;
    return (shrinkOffset / pinExtent).clamp(0.0, 1.0).toDouble();
  }

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent + pinExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => builder(
    context,
    progressFor(shrinkOffset: shrinkOffset, pinExtent: pinExtent),
  );

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      oldDelegate is! MotionPathPinnedHeaderDelegate ||
      oldDelegate.extent != extent ||
      oldDelegate.pinExtent != pinExtent ||
      oldDelegate.builder != builder;
}

/// Sliver that pins its content using [MotionPathPinnedHeaderDelegate].
///
/// Place it in a `CustomScrollView`'s slivers. This is the common top-pinning
/// case; arbitrary pinning stays the host's job through a `Stack` positioned
/// from `MotionPathViewportSample.paintOffset`, which already carries the
/// resolved geometry.
class MotionPathPinnedHeader extends StatelessWidget {
  /// Creates a pinned sliver section.
  const MotionPathPinnedHeader({
    required this.extent,
    required this.pinExtent,
    required this.builder,
    super.key,
  });

  /// Height the section keeps while pinned, in logical pixels.
  final double extent;

  /// Scroll distance consumed while the section stays pinned.
  final double pinExtent;

  /// Builds the pinned content for the current progress.
  final MotionPathPinnedBuilder builder;

  @override
  Widget build(BuildContext context) => SliverPersistentHeader(
    pinned: true,
    delegate: MotionPathPinnedHeaderDelegate(
      extent: extent,
      pinExtent: pinExtent,
      builder: builder,
    ),
  );
}
