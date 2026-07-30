import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter/widgets.dart';

import '../painters/motion_path_patch_painter.dart';
import 'motion_path_patch_source.dart';

/// Hip height authored by the Walker pelvis track.
const double kMotionPathWalkerHipY = 148;

/// Thigh length authored by the Walker rig.
const double kMotionPathWalkerThigh = 62;

/// Shin length authored by the Walker rig.
const double kMotionPathWalkerShin = 56;

/// Ground line, derived from the leg chain exactly like the reference demo.
const double kMotionPathWalkerGroundY =
    kMotionPathWalkerHipY + kMotionPathWalkerThigh + kMotionPathWalkerShin;

/// Visual weight of a bone, mirroring the reference stylesheet's tones.
enum MotionPathWalkerTone {
  /// Torso chain, drawn thickest and above the far side.
  core,

  /// Near-side limbs, drawn in front of the body.
  near,

  /// Far-side limbs, drawn behind and dimmed.
  far,
}

/// Paint order: the far side sits behind the torso, the near side in front.
const List<MotionPathWalkerTone> kMotionPathWalkerToneOrder =
    <MotionPathWalkerTone>[
  MotionPathWalkerTone.far,
  MotionPathWalkerTone.core,
  MotionPathWalkerTone.near,
];

/// How a tone is painted.
@immutable
class MotionPathWalkerToneStyle {
  /// Creates a tone style.
  const MotionPathWalkerToneStyle({
    required this.argb,
    required this.thickness,
    required this.opacity,
  });

  /// Stroke colour as packed ARGB data.
  final int argb;

  /// Stroke width in logical pixels.
  final double thickness;

  /// Normalized stroke opacity.
  final double opacity;
}

/// Tone styling, flattened from the reference CSS gradients into solid strokes.
const Map<MotionPathWalkerTone, MotionPathWalkerToneStyle>
    kMotionPathWalkerToneStyles = <MotionPathWalkerTone, MotionPathWalkerToneStyle>{
  MotionPathWalkerTone.core:
      MotionPathWalkerToneStyle(argb: 0xFF6E82FF, thickness: 24, opacity: 1),
  MotionPathWalkerTone.near:
      MotionPathWalkerToneStyle(argb: 0xFFFF8F55, thickness: 16, opacity: 1),
  MotionPathWalkerTone.far:
      MotionPathWalkerToneStyle(argb: 0xFF8C9ED0, thickness: 13, opacity: 0.62),
};

/// One drawn segment of the rig.
///
/// `drawLength` is the visual length of the bone leaving this joint. A zero
/// length means the track is a pure joint that carries no bone of its own.
@immutable
class MotionPathWalkerBone {
  /// Creates a bone description.
  const MotionPathWalkerBone({
    required this.id,
    required this.drawLength,
    required this.tone,
  });

  /// Track id whose composed patch positions this bone.
  final String id;

  /// Visual length in logical pixels.
  final double drawLength;

  /// Paint weight.
  final MotionPathWalkerTone tone;

  @override
  bool operator ==(Object other) =>
      other is MotionPathWalkerBone &&
      other.id == id &&
      other.drawLength == drawLength &&
      other.tone == tone;

  @override
  int get hashCode => Object.hash(id, drawLength, tone);
}

/// A joint dot worth drawing so the observed chain is visible.
@immutable
class MotionPathWalkerJoint {
  /// Creates a joint description.
  const MotionPathWalkerJoint({required this.id, required this.size});

  /// Track id whose composed patch positions this joint.
  final String id;

  /// Diameter in logical pixels.
  final double size;

  @override
  bool operator ==(Object other) =>
      other is MotionPathWalkerJoint && other.id == id && other.size == size;

  @override
  int get hashCode => Object.hash(id, size);
}

/// The Walker skeleton, ported from the reference `BONES` table.
const List<MotionPathWalkerBone> kMotionPathWalkerBones = <MotionPathWalkerBone>[
  MotionPathWalkerBone(id: 'spine', drawLength: 78, tone: MotionPathWalkerTone.core),
  MotionPathWalkerBone(id: 'chest', drawLength: 0, tone: MotionPathWalkerTone.core),
  MotionPathWalkerBone(id: 'head', drawLength: 0, tone: MotionPathWalkerTone.core),
  MotionPathWalkerBone(id: 'arm-far-upper', drawLength: 44, tone: MotionPathWalkerTone.far),
  MotionPathWalkerBone(id: 'arm-far-fore', drawLength: 40, tone: MotionPathWalkerTone.far),
  MotionPathWalkerBone(id: 'leg-far-thigh', drawLength: 62, tone: MotionPathWalkerTone.far),
  MotionPathWalkerBone(id: 'leg-far-shin', drawLength: 56, tone: MotionPathWalkerTone.far),
  MotionPathWalkerBone(id: 'leg-far-foot', drawLength: 26, tone: MotionPathWalkerTone.far),
  MotionPathWalkerBone(id: 'arm-near-upper', drawLength: 44, tone: MotionPathWalkerTone.near),
  MotionPathWalkerBone(id: 'arm-near-fore', drawLength: 40, tone: MotionPathWalkerTone.near),
  MotionPathWalkerBone(id: 'leg-near-thigh', drawLength: 62, tone: MotionPathWalkerTone.near),
  MotionPathWalkerBone(id: 'leg-near-shin', drawLength: 56, tone: MotionPathWalkerTone.near),
  MotionPathWalkerBone(id: 'leg-near-foot', drawLength: 26, tone: MotionPathWalkerTone.near),
];

/// The joints the reference demo draws dots on.
const List<MotionPathWalkerJoint> kMotionPathWalkerJoints = <MotionPathWalkerJoint>[
  MotionPathWalkerJoint(id: 'pelvis', size: 16),
  MotionPathWalkerJoint(id: 'chest', size: 14),
  MotionPathWalkerJoint(id: 'leg-near-shin', size: 12),
  MotionPathWalkerJoint(id: 'leg-near-foot', size: 10),
  MotionPathWalkerJoint(id: 'arm-near-fore', size: 10),
];

/// A bone resolved into world space for one composed frame.
@immutable
class MotionPathWalkerSegment {
  /// Creates a resolved segment.
  const MotionPathWalkerSegment({
    required this.bone,
    required this.origin,
    required this.tip,
  });

  /// The bone this segment came from.
  final MotionPathWalkerBone bone;

  /// Joint the bone leaves, in rig-local pixels.
  final Offset origin;

  /// Far end of the bone.
  final Offset tip;

  /// Painted length, which must equal the authored draw length.
  double get length => (tip - origin).distance;
}

/// Folds [opacity] into the alpha channel of [argb].
///
/// Deliberately arithmetic rather than a framework colour helper: those have
/// churned across SDK versions, and the renderer boundary already speaks ARGB.
Color motionPathArgbWithOpacity(int argb, double opacity) {
  final int source = (argb >> 24) & 0xFF;
  var alpha = (source * opacity).round();
  if (alpha < 0) {
    alpha = 0;
  } else if (alpha > 255) {
    alpha = 255;
  }
  return Color.fromARGB(alpha, (argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);
}

/// Resolves the drawn bones for one frame of composed patches.
///
/// A bone rotates around its own joint, so [MotionPathWalkerSegment.origin] is
/// the patch position and the tip extends along the composed world rotation.
/// Patch rotation is authored in degrees, which is why the conversion happens
/// here rather than in the pure Dart core.
List<MotionPathWalkerSegment> resolveWalkerSegments(
  Map<String, Map<String, Object?>> patches, {
  List<MotionPathWalkerBone> bones = kMotionPathWalkerBones,
}) {
  final List<MotionPathWalkerSegment> segments = <MotionPathWalkerSegment>[];
  for (final MotionPathWalkerBone bone in bones) {
    if (bone.drawLength <= 0) continue;
    final Map<String, Object?>? patch = patches[bone.id];
    if (patch == null) continue;
    final MotionPathPatchTransform transform =
        MotionPathPatchTransform.fromPatch(patch);
    final Offset origin = Offset(transform.translateX, transform.translateY);
    final double radians = transform.rotationRadians;
    segments.add(
      MotionPathWalkerSegment(
        bone: bone,
        origin: origin,
        tip: origin +
            Offset(math.cos(radians), math.sin(radians)) * bone.drawLength,
      ),
    );
  }
  return segments;
}

/// Paints the Walker rig from composed patches.
///
/// The painter listens to the patch source directly, so a scrubbing rig repaints
/// without rebuilding a single widget.
class MotionPathWalkerPainter extends CustomPainter {
  /// Creates a painter bound to [source].
  MotionPathWalkerPainter({
    required this.source,
    this.bones = kMotionPathWalkerBones,
    this.joints = kMotionPathWalkerJoints,
    this.groundY = kMotionPathWalkerGroundY,
    this.backgroundArgb = 0xFF0B0D16,
  }) : super(repaint: source);

  /// Publishes composed patches.
  final MotionPathPatchSource source;

  /// Bone table to draw.
  final List<MotionPathWalkerBone> bones;

  /// Joint dots to draw.
  final List<MotionPathWalkerJoint> joints;

  /// Ground line height in rig-local pixels.
  final double groundY;

  /// Colour used to knock a hole in each joint dot.
  final int backgroundArgb;

  static const double _headRadius = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, Map<String, Object?>> patches = source.patches;
    _paintGround(canvas, size);
    _paintShadow(canvas, patches);
    for (final MotionPathWalkerTone tone in kMotionPathWalkerToneOrder) {
      _paintTone(canvas, patches, tone);
    }
    _paintHead(canvas, patches);
    _paintJoints(canvas, patches);
  }

  void _paintGround(Canvas canvas, Size size) {
    final Paint ground = Paint()
      ..color = const Color(0x38FFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), ground);
  }

  void _paintShadow(Canvas canvas, Map<String, Map<String, Object?>> patches) {
    final Map<String, Object?>? pelvis = patches['pelvis'];
    if (pelvis == null) return;
    final MotionPathPatchTransform transform =
        MotionPathPatchTransform.fromPatch(pelvis);
    // The hip height already encodes the bounce, so no second track is needed.
    final double lift = (kMotionPathWalkerHipY - transform.translateY) / 5;
    final double opacity = (0.3 - lift * 0.06).clamp(0.0, 1.0);
    final double width = 104 * (1 - lift * 0.08);
    final Paint shadow = Paint()..color = Color.fromRGBO(0, 0, 0, opacity);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(transform.translateX, groundY + 10),
        width: width,
        height: 18,
      ),
      shadow,
    );
  }

  void _paintTone(
    Canvas canvas,
    Map<String, Map<String, Object?>> patches,
    MotionPathWalkerTone tone,
  ) {
    final MotionPathWalkerToneStyle style = kMotionPathWalkerToneStyles[tone]!;
    final Paint stroke = Paint()
      ..color = motionPathArgbWithOpacity(style.argb, style.opacity)
      ..strokeWidth = style.thickness
      ..strokeCap = StrokeCap.round;
    final List<MotionPathWalkerBone> toned = <MotionPathWalkerBone>[
      for (final MotionPathWalkerBone bone in bones)
        if (bone.tone == tone) bone,
    ];
    for (final MotionPathWalkerSegment segment
        in resolveWalkerSegments(patches, bones: toned)) {
      canvas.drawLine(segment.origin, segment.tip, stroke);
    }
  }

  void _paintHead(Canvas canvas, Map<String, Map<String, Object?>> patches) {
    final Map<String, Object?>? head = patches['head'];
    if (head == null) return;
    final MotionPathPatchTransform transform =
        MotionPathPatchTransform.fromPatch(head);
    final Offset centre = Offset(transform.translateX, transform.translateY);
    canvas.drawCircle(centre, _headRadius, Paint()..color = const Color(0xFFDCE4FF));
    // The head track's world rotation points UP the neck while the sprite faces
    // right, so the eye is placed a quarter turn on from the composed angle.
    final double facing = transform.rotationRadians + math.pi / 2;
    canvas.drawCircle(
      centre + Offset(math.cos(facing), math.sin(facing)) * 13,
      2.5,
      Paint()..color = const Color(0xFF10142A),
    );
  }

  void _paintJoints(Canvas canvas, Map<String, Map<String, Object?>> patches) {
    final Paint fill = Paint()..color = Color(backgroundArgb);
    final Paint edge = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final MotionPathWalkerJoint joint in joints) {
      final Map<String, Object?>? patch = patches[joint.id];
      if (patch == null) continue;
      final MotionPathPatchTransform transform =
          MotionPathPatchTransform.fromPatch(patch);
      // A dot has no orientation, so the inherited world rotation is dropped.
      final Offset centre = Offset(transform.translateX, transform.translateY);
      canvas.drawCircle(centre, joint.size / 2, fill);
      canvas.drawCircle(centre, joint.size / 2, edge);
    }
  }

  @override
  bool shouldRepaint(covariant MotionPathWalkerPainter oldDelegate) =>
      oldDelegate.source != source ||
      oldDelegate.groundY != groundY ||
      oldDelegate.backgroundArgb != backgroundArgb ||
      !listEquals<MotionPathWalkerBone>(oldDelegate.bones, bones) ||
      !listEquals<MotionPathWalkerJoint>(oldDelegate.joints, joints);
}

/// Renders the Walker rig for a [MotionPathPatchSource].
///
/// There is no [AnimatedBuilder] here on purpose: the painter subscribes to the
/// source, so a scrubbing rig repaints without a rebuild or a per-frame
/// `setState`.
class MotionPathWalkerScene extends StatelessWidget {
  /// Creates a Walker scene bound to [source].
  const MotionPathWalkerScene({
    required this.source,
    this.size = const Size(760, 300),
    this.bones = kMotionPathWalkerBones,
    this.joints = kMotionPathWalkerJoints,
    super.key,
  });

  /// Publishes composed patches.
  final MotionPathPatchSource source;

  /// Rig box size in logical pixels. Patch coordinates are relative to its
  /// top-left corner, matching the reference demo's world origin.
  final Size size;

  /// Bone table to draw.
  final List<MotionPathWalkerBone> bones;

  /// Joint dots to draw.
  final List<MotionPathWalkerJoint> joints;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: MotionPathWalkerPainter(source: source, bones: bones, joints: joints),
    );
  }
}
