import 'motionpath_plugin.dart';

/// Passes authored CSS custom properties to a renderer-neutral `cssVariables`
/// output without importing a browser or Flutter rendering API.
const MotionPathPlugin cssVariablePlugin = MotionPathPlugin(
  name: 'css-variable',
  keys: <String>['cssVariables'],
  inputs: <String>['cssVariables'],
  outputs: <String>['cssVariables'],
  internalKeys: <String>['cssVariablesInput'],
  stage: 30,
  compose: _composeCssVariables,
);

Map<String, Object?>? _composeCssVariables(Map<String, Object?> raw) {
  final Object? value = raw['cssVariables'];
  if (value is! Map<Object?, Object?>) {
    return null;
  }
  final Map<String, Object?> variables = <String, Object?>{};
  value.forEach((Object? key, Object? entry) {
    if (key is String && key.startsWith('--')) {
      variables[key] = entry;
    }
  });
  return variables.isEmpty
      ? null
      : <String, Object?>{'cssVariables': variables};
}
