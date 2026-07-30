import '../math/fk_math.dart';

/// Patch keys that describe how a patch was produced, not what to render.
///
/// These are stripped before a patch crosses the renderer boundary, mirroring
/// the `internalKeys` contract in the JavaScript plugin registry.
const List<String> kMotionPathInternalPatchKeys = <String>[
  'parentWorld',
  'boneLength',
  'boneRotation',
];

/// True when [patch] authors forward-kinematics bone data.
bool patchDeclaresForwardKinematics(Map<String, Object?> patch) =>
    patch.containsKey('boneLength') || patch.containsKey('boneRotation');

/// Folds an observed `parentWorld` and the authored bone into world x/y/rotation.
///
/// Tracks that author no bone data are returned untouched, so a root track keeps
/// the position it authored directly.
Map<String, Object?> applyForwardKinematics(Map<String, Object?> patch) {
  if (!patchDeclaresForwardKinematics(patch)) return patch;
  final Object? rawParent = patch['parentWorld'];
  final MotionPathWorldTransform parent = rawParent is Map
      ? MotionPathWorldTransform.fromPatch(Map<String, Object?>.from(rawParent))
      : const MotionPathWorldTransform();
  final Object? boneLength = patch['boneLength'];
  final Object? boneRotation = patch['boneRotation'] ?? patch['rotation'];
  final MotionPathWorldTransform local = MotionPathWorldTransform(
    x: boneLength is num ? boneLength.toDouble() : 0,
    rotation: boneRotation is num ? boneRotation.toDouble() : 0,
  );
  final Map<String, Object?> result = Map<String, Object?>.of(patch);
  result.addAll(composeWorld(parent, local).toPatch());
  return result;
}

/// Removes [kMotionPathInternalPatchKeys] so renderers see a flat patch.
Map<String, Object?> stripInternalPatchKeys(Map<String, Object?> patch) {
  final Map<String, Object?> result = Map<String, Object?>.of(patch);
  for (final String key in kMotionPathInternalPatchKeys) {
    result.remove(key);
  }
  return result;
}
