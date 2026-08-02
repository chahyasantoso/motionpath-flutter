import '../composition/compose_patch.dart';
import '../composition/layout_delegate.dart';
import '../contract/motionpath_types.dart';
import '../interpolation/color_value.dart';
import '../interpolation/easing.dart';
import '../interpolation/interpolator.dart';
import '../plugins/motionpath_plugin.dart';

/// A wired observation between two runtime tracks.
class MotionPathObservation {
  const MotionPathObservation({required this.source, this.role = 'output', this.input});
  final MotionPathTrackRuntime source;
  final String role;
  final String? input;
  bool get isInput => role == 'input';
}

/// A mounted track: one normalized playhead plus its composition.
class MotionPathTrackRuntime implements MotionPathLayoutChild {
  MotionPathTrackRuntime(this.id, {Map<String, List<MotionPathStop>> properties = const <String, List<MotionPathStop>>{}, List<MotionPathStop> stops = const <MotionPathStop>[], List<MotionPathPlugin>? plugins, MotionPathLayoutDelegate? layoutDelegate, double duration = 0}) : properties = Map<String, List<MotionPathStop>>.unmodifiable(properties), stops = List<MotionPathStop>.unmodifiable(stops), layoutDelegate = layoutDelegate ?? kGaplessLayoutDelegate, plugins = List<MotionPathPlugin>.unmodifiable(plugins ?? MotionPathPluginRegistry().resolve(_authoredKeys(properties, stops))), duration = _finiteNonNegative(duration, 'duration');

  static Iterable<String> _authoredKeys(Map<String, List<MotionPathStop>> properties, List<MotionPathStop> stops) => properties.isEmpty && stops.isNotEmpty ? const <String>['value'] : properties.keys;
  static double _finiteNonNegative(double value, String name) {
    if (!value.isFinite || value < 0) throw ArgumentError.value(value, name, 'must be finite and non-negative');
    return value;
  }

  final String id;
  final Map<String, List<MotionPathStop>> properties;
  final List<MotionPathStop> stops;
  final List<MotionPathPlugin> plugins;
  final MotionPathLayoutDelegate layoutDelegate;
  final double duration;
  double _progress = 0;
  double get progress => _progress;
  set progress(double value) {
    if (!value.isFinite) throw ArgumentError.value(value, 'progress', 'must be finite');
    _progress = value.clamp(0.0, 1.0).toDouble();
  }

  void Function(MotionPathTrackRuntime child, double offset)? get onChildSpawned => _onChildSpawned;
  set onChildSpawned(void Function(MotionPathTrackRuntime child, double offset)? callback) { _guardCallbackWire('onChildSpawned', _onChildSpawned, callback); _onChildSpawned = callback; }
  void Function(MotionPathTrackRuntime child)? get onChildRemoved => _onChildRemoved;
  set onChildRemoved(void Function(MotionPathTrackRuntime child)? callback) { _guardCallbackWire('onChildRemoved', _onChildRemoved, callback); _onChildRemoved = callback; }
  void Function(MotionPathTrackRuntime child, double offset)? get onChildReflowed => _onChildReflowed;
  set onChildReflowed(void Function(MotionPathTrackRuntime child, double offset)? callback) { _guardCallbackWire('onChildReflowed', _onChildReflowed, callback); _onChildReflowed = callback; }
  static void _guardCallbackWire<T>(String name, T? current, T? next) { if (current != null && next != null) throw StateError('$name is already wired; only one host is allowed.'); }
  void Function(MotionPathTrackRuntime child, double offset)? _onChildSpawned;
  void Function(MotionPathTrackRuntime child)? _onChildRemoved;
  void Function(MotionPathTrackRuntime child, double offset)? _onChildReflowed;
  final List<MotionPathObservation> _observed = <MotionPathObservation>[];
  final List<void Function(Map<String, Object?>)> _listeners = <void Function(Map<String, Object?>)>[];
  final Map<String, MotionPathTrackRuntime> _children = <String, MotionPathTrackRuntime>{};
  MotionPathTrackRuntime? _parent;
  double _currentOffset = 0;
  double _staggerOffset = 0;
  bool _disposed = false;
  List<MotionPathObservation> get observations => List<MotionPathObservation>.unmodifiable(_observed);
  @override double get currentOffset => _currentOffset;
  double get staggerOffset => _staggerOffset;
  MotionPathTrackRuntime? get parent => _parent;
  List<MotionPathTrackRuntime> get children => List<MotionPathTrackRuntime>.unmodifiable(_children.values);
  int get childCount => _children.length;
  bool get isDisposed => _disposed;
  MotionPathTrackRuntime? getChild(String childId) => _children[childId];

  void addChild(MotionPathTrackRuntime child, {double stagger = 0}) {
    if (_disposed) throw StateError('Track "$id" is disposed.');
    _finiteNonNegative(stagger, 'stagger');
    final MotionPathTrackRuntime? existingParent = child._parent;
    if (existingParent != null) throw StateError('Track "${child.id}" is already a child of "${existingParent.id}".');
    if (_children.containsKey(child.id)) throw StateError('Track "$id" already has a child "${child.id}".');
    final double offset = layoutDelegate.computeSpawnOffset(<MotionPathLayoutChild>[..._children.values], stagger: stagger);
    child._parent = this;
    child._staggerOffset = stagger;
    child._currentOffset = offset;
    _children[child.id] = child;
    _onChildSpawned?.call(child, offset);
  }

  void removeChild(String childId) {
    final MotionPathTrackRuntime? child = _children[childId];
    if (child == null) return;
    final List<MotionPathLayoutChild> siblings = <MotionPathLayoutChild>[..._children.values];
    _children.remove(childId);
    child._parent = null;
    _onChildRemoved?.call(child);
    for (final MotionPathReflowTarget target in layoutDelegate.computeReflow(siblings, child, stagger: child._staggerOffset)) {
      final MotionPathLayoutChild moved = target.child;
      if (moved is! MotionPathTrackRuntime) {
        continue;
      }
      moved._currentOffset = target.offset;
      _onChildReflowed?.call(moved, target.offset);
    }
  }

  void observe(MotionPathTrackRuntime source, {String role = 'output', String? input}) {
    if (role != 'input' && role != 'output') throw ArgumentError.value(role, 'role', 'must be input or output');
    if (role == 'input' && (input == null || input.isEmpty)) throw ArgumentError.value(input, 'input', 'is required for an input observation');
    if (role == 'output' && input != null) throw ArgumentError.value(input, 'input', 'must be omitted for an output observation');
    _observed.add(MotionPathObservation(source: source, role: role, input: input));
  }
  void removeObserved(MotionPathTrackRuntime source) => _observed.removeWhere((MotionPathObservation observation) => observation.source == source);

  Map<String, Object?> snapshot() {
    final Map<String, List<MotionPathStop>> authored = properties.isEmpty && stops.isNotEmpty ? <String, List<MotionPathStop>>{'value': stops} : properties;
    final Map<String, Object?> raw = <String, Object?>{};
    for (final MapEntry<String, List<MotionPathStop>> entry in authored.entries) raw[entry.key] = interpolateStops(entry.value, progress, blend: blendForProperty(entry.key));
    raw['progress'] = progress;
    return raw;
  }

  Map<String, Object?> compose({Map<String, Object?>? rawData, Map<MotionPathTrackRuntime, Map<String, Object?>?>? context}) {
    final Map<MotionPathTrackRuntime, Map<String, Object?>?> ctx = context ?? <MotionPathTrackRuntime, Map<String, Object?>?>{};
    if (ctx.containsKey(this)) {
      final Map<String, Object?>? cached = ctx[this];
      if (cached != null) return cached;
      return composePatch(plugins, rawData ?? snapshot());
    }
    ctx[this] = null;
    Map<String, Object?> raw = rawData ?? snapshot();
    for (final MotionPathObservation observation in _observed) {
      if (!observation.isInput) {
        continue;
      }
      final String? key = observation.input;
      if (key == null || key.isEmpty) throw StateError('Track "$id" contains an input observation without a target key.');
      raw = <String, Object?>{...raw, key: observation.source.compose(context: ctx)};
    }
    Map<String, Object?> patch = composePatch(plugins, raw);
    for (final MotionPathObservation observation in _observed) {
      if (!observation.isInput) {
        patch = mergePatches(patch, observation.source.compose(context: ctx));
      }
    }
    ctx[this] = patch;
    return patch;
  }

  void seek(double value) {
    if (!value.isFinite) throw ArgumentError.value(value, 'value', 'must be finite');
    progress = value;
    if (_listeners.isEmpty) return;
    final Map<String, Object?> patch = compose();
    for (final void Function(Map<String, Object?>) listener in List<void Function(Map<String, Object?>)>.of(_listeners)) listener(patch);
  }
  void Function() subscribe(void Function(Map<String, Object?>) listener) {
    if (_disposed) throw StateError('Track "$id" is disposed.');
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _listeners.clear();
    _observed.clear();
    for (final MotionPathTrackRuntime child in List<MotionPathTrackRuntime>.of(_children.values)) {
      child._parent = null;
      child.dispose();
    }
    _children.clear();
    _parent = null;
    onChildSpawned = null;
    onChildRemoved = null;
    onChildReflowed = null;
  }
}

ValueBlend blendForProperty(String propertyKey) => kMotionPathColorKeys.contains(propertyKey) ? blendColorValues : MotionPathInterpolators.value;

const Map<String, String> kMotionPathStaticPayloadKeys = <String, String>{
  'path': 'points',
  'imageSequence': 'frames',
};

Object _keyframePayload(Map<String, Object?> config, String propertyKey, String payloadKey) {
  final Object? payload = config[payloadKey];
  if (payload is! List<Object?> || payload.isEmpty) {
    throw ArgumentError.value(payload, payloadKey, 'A "$propertyKey" keyframe requires a non-empty "$payloadKey" list');
  }
  final List<Object?> entries = List<Object?>.unmodifiable(payload);
  if (propertyKey != 'path') return entries;
  return Map<String, Object?>.unmodifiable(<String, Object?>{
    'points': entries,
    'stops': config['stops'],
    if (config['autoRotate'] == true) 'autoRotate': true,
    if (config.containsKey('ease')) 'ease': config['ease'],
    if (config.containsKey('anchor')) 'anchor': config['anchor'],
  });
}

List<MotionPathStop> stopsFromKeyframe(Object? raw, {String propertyKey = ''}) {
  final Map<String, Object?> config = asStringKeyedMap(raw);
  final Object? rawStops = config['stops'];
  if (rawStops is! List<Object?>) return const <MotionPathStop>[];
  final Easing keyframeEase = resolveEasing(config['ease']);
  final bool isColor = kMotionPathColorKeys.contains(propertyKey);
  final String? payloadKey = kMotionPathStaticPayloadKeys[propertyKey];
  final Object? payload = payloadKey == null ? null : _keyframePayload(config, propertyKey, payloadKey);
  final List<MotionPathStop> result = <MotionPathStop>[];
  for (final Object? candidate in rawStops) {
    final Map<String, Object?> stop = asStringKeyedMap(candidate);
    if (stop.isEmpty) continue;
    final Object? progress = stop['p'];
    final Object? value = stop['v'];
    result.add(MotionPathStop(progress: progress is num ? progress.toDouble() : 0, value: payload ?? (isColor ? (parseColorArgb(value) ?? value) : value), ease: stop.containsKey('ease') ? resolveEasing(stop['ease']) : keyframeEase));
  }
  return List<MotionPathStop>.unmodifiable(result);
}

Map<String, List<MotionPathStop>> propertiesFromTrack(MotionPathTrack track) {
  final Map<String, List<MotionPathStop>> result = <String, List<MotionPathStop>>{};
  for (final MapEntry<String, Object?> entry in track.keyframes.entries) {
    final List<MotionPathStop> stops = stopsFromKeyframe(entry.value, propertyKey: entry.key);
    if (stops.isNotEmpty) result[entry.key] = stops;
  }
  return result;
}
