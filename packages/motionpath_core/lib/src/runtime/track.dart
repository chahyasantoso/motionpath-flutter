import '../composition/compose_patch.dart';
import '../composition/layout_delegate.dart';
import '../contract/motionpath_types.dart';
import '../interpolation/color_value.dart';
import '../interpolation/easing.dart';
import '../interpolation/interpolator.dart';
import '../plugins/motionpath_plugin.dart';

/// A wired observation between two runtime tracks.
class MotionPathObservation {
  /// Creates an observation.
  const MotionPathObservation({
    required this.source,
    this.role = 'output',
    this.input,
  });

  /// Observed track.
  final MotionPathTrackRuntime source;

  /// Either `input` or `output`.
  final String role;

  /// Key the source patch is wrapped under, for `input` observations.
  final String? input;

  /// Whether this observation feeds the target's plugins.
  bool get isInput => role == 'input';
}

/// A mounted track: one normalized playhead plus its composition.
class MotionPathTrackRuntime implements MotionPathLayoutChild {
  /// Creates a runtime track.
  MotionPathTrackRuntime(
    this.id, {
    Map<String, List<MotionPathStop>> properties =
        const <String, List<MotionPathStop>>{},
    List<MotionPathStop> stops = const <MotionPathStop>[],
    List<MotionPathPlugin>? plugins,
    MotionPathLayoutDelegate? layoutDelegate,
    this.duration = 0,
  })  : properties =
            Map<String, List<MotionPathStop>>.unmodifiable(properties),
        stops = List<MotionPathStop>.unmodifiable(stops),
        layoutDelegate = layoutDelegate ?? kGaplessLayoutDelegate,
        plugins = List<MotionPathPlugin>.unmodifiable(
          plugins ??
              MotionPathPluginRegistry()
                  .resolve(_authoredKeys(properties, stops)),
        );

  static Iterable<String> _authoredKeys(
    Map<String, List<MotionPathStop>> properties,
    List<MotionPathStop> stops,
  ) =>
      properties.isEmpty && stops.isNotEmpty
          ? const <String>['value']
          : properties.keys;

  /// Track id.
  final String id;

  /// Authored stops per property.
  final Map<String, List<MotionPathStop>> properties;

  /// Single unnamed property, used by simple tracks.
  final List<MotionPathStop> stops;

  /// Plugins resolved for this track's authored keys.
  final List<MotionPathPlugin> plugins;

  /// Placement policy for this track's children.
  final MotionPathLayoutDelegate layoutDelegate;

  /// Track duration in seconds. Zero means the motion owns timing.
  final double duration;

  /// Normalized playhead in `[0, 1]`.
  double progress = 0;

  /// Called after a child is placed, with its settled offset.
  ///
  /// The host uses this to mount the child at that offset. The core never
  /// schedules anything itself.
  void Function(MotionPathTrackRuntime child, double offset)? onChildSpawned;

  /// Called after a child is detached, before its siblings reflow.
  void Function(MotionPathTrackRuntime child)? onChildRemoved;

  /// Called for each survivor the layout policy moved.
  void Function(MotionPathTrackRuntime child, double offset)? onChildReflowed;

  final List<MotionPathObservation> _observed = <MotionPathObservation>[];
  final List<void Function(Map<String, Object?>)> _listeners =
      <void Function(Map<String, Object?>)>[];
  final Map<String, MotionPathTrackRuntime> _children =
      <String, MotionPathTrackRuntime>{};
  MotionPathTrackRuntime? _parent;
  double _currentOffset = 0;
  double _staggerOffset = 0;
  bool _disposed = false;

  /// Wired observations, in wiring order.
  List<MotionPathObservation> get observations =>
      List<MotionPathObservation>.unmodifiable(_observed);

  /// Settled logical offset inside the parent, in seconds.
  ///
  /// Bookkeeping only. It is the value the host mounts against; this track
  /// never advances a child's playhead on its own.
  @override
  double get currentOffset => _currentOffset;

  /// Stagger this track was spawned with, in seconds.
  double get staggerOffset => _staggerOffset;

  /// Parent track, or null when this track is a root.
  MotionPathTrackRuntime? get parent => _parent;

  /// Live children, in insertion order.
  List<MotionPathTrackRuntime> get children =>
      List<MotionPathTrackRuntime>.unmodifiable(_children.values);

  /// Number of live children.
  int get childCount => _children.length;

  /// Whether [dispose] has already run.
  bool get isDisposed => _disposed;

  /// Finds a child by id.
  MotionPathTrackRuntime? getChild(String childId) => _children[childId];

  /// Adds [child] and places it through this track's layout policy.
  ///
  /// Throws when this track is disposed, when [child] already has a parent, or
  /// when a child with the same id is already present. Re-parenting silently
  /// would leave two parents believing they own the same offset.
  void addChild(MotionPathTrackRuntime child, {double stagger = 0}) {
    if (_disposed) {
      throw StateError('Track "$id" is disposed.');
    }
    final MotionPathTrackRuntime? existingParent = child._parent;
    if (existingParent != null) {
      throw StateError(
        'Track "${child.id}" is already a child of "${existingParent.id}".',
      );
    }
    if (_children.containsKey(child.id)) {
      throw StateError('Track "$id" already has a child "${child.id}".');
    }
    final double offset = layoutDelegate.computeSpawnOffset(
      <MotionPathLayoutChild>[..._children.values],
      stagger: stagger,
    );
    child._parent = this;
    child._staggerOffset = stagger;
    child._currentOffset = offset;
    _children[child.id] = child;
    onChildSpawned?.call(child, offset);
  }

  /// Removes the child with [childId] and applies the resulting reflow plan.
  ///
  /// Removing an unknown id is a no-op.
  void removeChild(String childId) {
    final MotionPathTrackRuntime? child = _children[childId];
    if (child == null) {
      return;
    }
    // The policy reads the chain as it was, so it still contains the removed
    // child and can rank it.
    final List<MotionPathLayoutChild> siblings = <MotionPathLayoutChild>[
      ..._children.values,
    ];
    _children.remove(childId);
    child._parent = null;
    onChildRemoved?.call(child);
    for (final MotionPathReflowTarget target in layoutDelegate.computeReflow(
      siblings,
      child,
      stagger: child._staggerOffset,
    )) {
      final MotionPathLayoutChild moved = target.child;
      if (moved is! MotionPathTrackRuntime) {
        continue;
      }
      moved._currentOffset = target.offset;
      onChildReflowed?.call(moved, target.offset);
    }
  }

  /// Wires an observation. Observation is never reverse-linked.
  void observe(
    MotionPathTrackRuntime source, {
    String role = 'output',
    String? input,
  }) {
    if (role == 'input' && (input == null || input.isEmpty)) {
      return;
    }
    _observed.add(
      MotionPathObservation(source: source, role: role, input: input),
    );
  }

  /// Removes every observation of [source].
  void removeObserved(MotionPathTrackRuntime source) {
    _observed.removeWhere(
      (MotionPathObservation observation) => observation.source == source,
    );
  }

  /// Raw interpolated state, before plugins compose.
  ///
  /// Each property is blended by the rule its key needs: colour keys blend per
  /// channel, everything else uses the numeric default.
  Map<String, Object?> snapshot() {
    final Map<String, List<MotionPathStop>> authored =
        properties.isEmpty && stops.isNotEmpty
            ? <String, List<MotionPathStop>>{'value': stops}
            : properties;
    final Map<String, Object?> raw = <String, Object?>{};
    for (final MapEntry<String, List<MotionPathStop>> entry
        in authored.entries) {
      raw[entry.key] = interpolateStops(
        entry.value,
        progress,
        blend: blendForProperty(entry.key),
      );
    }
    raw['progress'] = progress;
    return raw;
  }

  /// Composes this track's renderer-neutral patch.
  ///
  /// [context] is created per external compose call. It caches resolved patches
  /// so diamonds are cheap, and uses a composing sentinel so a cycle degrades
  /// to a local compose instead of recursing forever.
  Map<String, Object?> compose({
    Map<String, Object?>? rawData,
    Map<MotionPathTrackRuntime, Map<String, Object?>?>? context,
  }) {
    final Map<MotionPathTrackRuntime, Map<String, Object?>?> ctx =
        context ?? <MotionPathTrackRuntime, Map<String, Object?>?>{};
    if (ctx.containsKey(this)) {
      final Map<String, Object?>? cached = ctx[this];
      if (cached != null) {
        return cached;
      }
      return composePatch(plugins, rawData ?? snapshot());
    }
    ctx[this] = null;

    Map<String, Object?> raw = rawData ?? snapshot();
    for (final MotionPathObservation observation in _observed) {
      if (!observation.isInput) {
        continue;
      }
      final String? key = observation.input;
      if (key == null || key.isEmpty) {
        continue;
      }
      raw = <String, Object?>{
        ...raw,
        key: observation.source.compose(context: ctx),
      };
    }

    Map<String, Object?> patch = composePatch(plugins, raw);
    for (final MotionPathObservation observation in _observed) {
      if (observation.isInput) {
        continue;
      }
      patch = mergePatches(patch, observation.source.compose(context: ctx));
    }
    ctx[this] = patch;
    return patch;
  }

  /// Moves the playhead and notifies subscribers with a composed patch.
  void seek(double value) {
    progress = value.clamp(0.0, 1.0).toDouble();
    if (_listeners.isEmpty) {
      return;
    }
    final Map<String, Object?> patch = compose();
    for (final void Function(Map<String, Object?>) listener
        in List<void Function(Map<String, Object?>)>.of(_listeners)) {
      listener(patch);
    }
  }

  /// Subscribes to composed patches. Returns a disposer.
  void Function() subscribe(void Function(Map<String, Object?>) listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  /// Releases subscriptions, observations, and the child chain.
  ///
  /// Disposal cascades to children and is idempotent, so a route change that
  /// tears down a parent cannot leave a child holding a listener.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _listeners.clear();
    _observed.clear();
    for (final MotionPathTrackRuntime child
        in List<MotionPathTrackRuntime>.of(_children.values)) {
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

/// Picks the value blend a property key needs.
///
/// Colour keys interpolate per channel; everything else uses the numeric and
/// switch-at-the-end default.
ValueBlend blendForProperty(String propertyKey) =>
    kMotionPathColorKeys.contains(propertyKey)
        ? blendColorValues
        : MotionPathInterpolators.value;

/// Reads authored stops out of one keyframe definition.
///
/// [propertyKey] decides whether stop values are normalized into packed ARGB
/// data. A stop's own `ease` wins over the keyframe-level `ease`, and an
/// unknown name degrades to linear instead of throwing.
List<MotionPathStop> stopsFromKeyframe(
  Object? raw, {
  String propertyKey = '',
}) {
  final Map<String, Object?> config = asStringKeyedMap(raw);
  final Object? rawStops = config['stops'];
  if (rawStops is! List<Object?>) {
    return const <MotionPathStop>[];
  }
  final Easing keyframeEase = resolveEasing(config['ease']);
  final bool isColor = kMotionPathColorKeys.contains(propertyKey);
  final List<MotionPathStop> result = <MotionPathStop>[];
  for (final Object? candidate in rawStops) {
    final Map<String, Object?> stop = asStringKeyedMap(candidate);
    if (stop.isEmpty) {
      continue;
    }
    final Object? progress = stop['p'];
    final Object? value = stop['v'];
    result.add(MotionPathStop(
      progress: progress is num ? progress.toDouble() : 0,
      value: isColor ? (parseColorArgb(value) ?? value) : value,
      ease: stop.containsKey('ease')
          ? resolveEasing(stop['ease'])
          : keyframeEase,
    ));
  }
  return List<MotionPathStop>.unmodifiable(result);
}

/// Extracts every authored property's stops from a track definition.
Map<String, List<MotionPathStop>> propertiesFromTrack(MotionPathTrack track) {
  final Map<String, List<MotionPathStop>> result =
      <String, List<MotionPathStop>>{};
  for (final MapEntry<String, Object?> entry in track.keyframes.entries) {
    final List<MotionPathStop> stops =
        stopsFromKeyframe(entry.value, propertyKey: entry.key);
    if (stops.isNotEmpty) {
      result[entry.key] = stops;
    }
  }
  return result;
}
