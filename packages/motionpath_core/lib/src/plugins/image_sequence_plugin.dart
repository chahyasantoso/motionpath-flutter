import 'motionpath_plugin.dart';

/// Selects one authored image frame from a normalized sequence.
///
/// The plugin reads `imageSequence` as a list of frame references and emits the
/// selected reference under `image`. It never loads or decodes image data.
const MotionPathPlugin imageSequencePlugin = MotionPathPlugin(
  name: 'image-sequence',
  keys: <String>['imageSequence'],
  inputs: <String>['progress'],
  outputs: <String>['image'],
  internalKeys: <String>['imageSequence'],
  stage: 20,
  compose: _composeImageSequence,
);

Map<String, Object?>? _composeImageSequence(Map<String, Object?> raw) {
  final Object? frames = raw['imageSequence'];
  if (frames is! List<Object?> || frames.isEmpty) {
    return null;
  }
  final double progress = raw['progress'] is num
      ? (raw['progress']! as num).toDouble().clamp(0.0, 1.0).toDouble()
      : 0;
  final int index = (progress * (frames.length - 1)).round();
  final Object? frame = frames[index];
  return frame == null ? null : <String, Object?>{'image': frame};
}
