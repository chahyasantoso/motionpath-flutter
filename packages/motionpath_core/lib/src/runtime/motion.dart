import '../graph/observation_graph.dart';
import 'track.dart';
import 'trigger.dart';

/// A mounted motion: one trigger, one playhead, and the tracks that share it.
class MotionPathMotionRuntime {
  /// Creates a runtime motion.
  MotionPathMotionRuntime({
    required this.id,
    required this.tracks,
    this.trigger,
    this.duration = 1,
  });

  /// Motion id.
  final String id;

  /// Mounted tracks.
  final List<MotionPathTrackRuntime> tracks;

  /// Trigger semantics, or null for an externally driven motion.
  final MotionPathTrigger? trigger;

  /// Motion duration in seconds.
  ///
  /// Mutable so an adapter can retime a mounted motion without remounting it.
  double duration;

  /// Normalized playhead in `[0, 1]`.
  double progress = 0;

  /// Whether the frame source should advance this motion.
  bool playing = false;

  /// Compiled observation graph.
  ObservationGraph? graph;

  /// Called with renderer-facing patches after each composed tick.
  ///
  /// This is the only hook a renderer needs, and the core never learns who
  /// listens: a `ChangeNotifier` on the Flutter side binds to it without the
  /// engine importing anything from Flutter.
  void Function(Map<String, Map<String, Object?>> patches)? onPatches;

  double _elapsed = 0;

  Map<String, Map<String, Object?>> _patches =
      const <String, Map<String, Object?>>{};

  /// The most recently composed renderer-facing patches, keyed by track id.
  Map<String, Map<String, Object?>> get patches => _patches;

  /// Compiled parent-before-child track ids.
  List<String> get graphOrder => graph == null
      ? const <String>[]
      : List<String>.unmodifiable(graph!.order);

  /// Stores the compiled graph and wires authored observations.
  void prepare(ObservationGraph nextGraph) {
    graph = nextGraph;
    final Map<String, MotionPathTrackRuntime> byId =
        <String, MotionPathTrackRuntime>{
      for (final MotionPathTrackRuntime track in tracks) track.id: track,
    };
    for (final ObservationEdge edge in nextGraph.edges) {
      final MotionPathTrackRuntime? target = byId[edge.target];
      final MotionPathTrackRuntime? source = byId[edge.source];
      if (target == null || source == null) {
        continue;
      }
      target.observe(source, role: edge.role, input: edge.input);
    }
  }

  /// Starts advancing on the frame source.
  void play() {
    playing = true;
  }

  /// Stops advancing on the frame source.
  void pause() {
    playing = false;
  }

  /// Flips the playhead around its midpoint.
  void reverse() => seek(1 - progress);

  /// Moves every track to a normalized [value].
  void seek(double value) {
    progress = value.clamp(0.0, 1.0).toDouble();
    for (final MotionPathTrackRuntime track in tracks) {
      track.seek(progress);
    }
  }

  /// Composes every track in the compiled order, sharing one context.
  Map<String, Map<String, Object?>> composeGraph() {
    final ObservationGraph? current = graph;
    if (current == null) {
      return const <String, Map<String, Object?>>{};
    }
    final Map<String, MotionPathTrackRuntime> byId =
        <String, MotionPathTrackRuntime>{
      for (final MotionPathTrackRuntime track in tracks) track.id: track,
    };
    final Map<MotionPathTrackRuntime, Map<String, Object?>?> context =
        <MotionPathTrackRuntime, Map<String, Object?>?>{};
    final Map<String, Map<String, Object?>> composed =
        <String, Map<String, Object?>>{};
    for (final String trackId in current.order) {
      final MotionPathTrackRuntime? track = byId[trackId];
      if (track == null) {
        continue;
      }
      composed[trackId] = track.compose(context: context);
    }
    _patches = composed;
    return composed;
  }

  /// Recomposes the graph and hands the patches to [onPatches].
  Map<String, Map<String, Object?>> publish() {
    final Map<String, Map<String, Object?>> composed = composeGraph();
    final void Function(Map<String, Map<String, Object?>>)? listener =
        onPatches;
    if (listener != null) {
      listener(composed);
    }
    return composed;
  }

  /// Advances the playhead by [delta] seconds and publishes the result.
  void tick(double delta) {
    final MotionPathTrigger? currentTrigger = trigger;
    final double span = duration <= 0 ? 1 : duration;
    if (currentTrigger == null) {
      seek(progress + delta / span);
    } else {
      _elapsed += delta;
      seek(currentTrigger.progressAt(_elapsed, span));
    }
    publish();
    if (progress < 1) {
      return;
    }
    if (currentTrigger == null || currentTrigger.isFinished(_elapsed, span)) {
      pause();
    }
  }

  /// Rewinds the trigger clock without touching authored data.
  void restart() {
    _elapsed = 0;
    seek(0);
  }

  /// Releases every track and subscription.
  void dispose() {
    onPatches = null;
    for (final MotionPathTrackRuntime track in tracks) {
      track.dispose();
    }
    tracks.clear();
    graph = null;
    playing = false;
    _patches = const <String, Map<String, Object?>>{};
  }
}
