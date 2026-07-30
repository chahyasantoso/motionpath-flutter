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
    this.stagger = 0,
  });

  /// Motion id.
  final String id;

  /// Mounted tracks.
  final List<MotionPathTrackRuntime> tracks;

  /// Trigger semantics, or null for an externally driven motion.
  final MotionPathTrigger? trigger;

  /// Motion duration in seconds.
  double duration;

  /// Delay between successive tracks, in seconds.
  final double stagger;

  /// Normalized playhead in `[0, 1]`.
  double progress = 0;

  /// Whether the frame source should advance this motion.
  bool playing = false;

  /// Compiled observation graph.
  ObservationGraph? graph;

  /// Called with renderer-facing patches after each composed tick.
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
    final Map<String, MotionPathTrackRuntime> byId = <String, MotionPathTrackRuntime>{
      for (final MotionPathTrackRuntime track in tracks) track.id: track,
    };
    for (final ObservationEdge edge in nextGraph.edges) {
      final MotionPathTrackRuntime? target = byId[edge.target];
      final MotionPathTrackRuntime? source = byId[edge.source];
      if (target == null || source == null) continue;
      target.observe(source, role: edge.role, input: edge.input);
    }
  }

  void play() => playing = true;
  void pause() => playing = false;
  void reverse() => seek(1 - progress);

  /// Moves the motion and applies its authored stagger to track playheads.
  void seek(double value) {
    progress = value.clamp(0.0, 1.0).toDouble();
    _elapsed = progress * (duration <= 0 ? 1 : duration);
    _seekTracks(_elapsed);
  }

  void _seekTracks(double elapsed) {
    final List<String> order = graph?.order ?? <String>[
      for (final MotionPathTrackRuntime track in tracks) track.id,
    ];
    final Map<String, int> indexById = <String, int>{
      for (int index = 0; index < order.length; index++) order[index]: index,
    };
    for (final MotionPathTrackRuntime track in tracks) {
      final double delay = stagger > 0 ? (indexById[track.id] ?? 0) * stagger : 0;
      final double span = track.duration > 0 ? track.duration : (duration <= 0 ? 1 : duration);
      final double local = span <= 0 ? 1 : (elapsed - delay) / span;
      track.seek(local.clamp(0.0, 1.0).toDouble());
    }
  }

  /// Composes every track in the compiled order, sharing one context.
  Map<String, Map<String, Object?>> composeGraph() {
    final ObservationGraph? current = graph;
    if (current == null) return const <String, Map<String, Object?>>{};
    final Map<String, MotionPathTrackRuntime> byId = <String, MotionPathTrackRuntime>{
      for (final MotionPathTrackRuntime track in tracks) track.id: track,
    };
    final Map<MotionPathTrackRuntime, Map<String, Object?>?> context =
        <MotionPathTrackRuntime, Map<String, Object?>?>{};
    final Map<String, Map<String, Object?>> composed = <String, Map<String, Object?>>{};
    for (final String trackId in current.order) {
      final MotionPathTrackRuntime? track = byId[trackId];
      if (track == null) continue;
      composed[trackId] = track.compose(context: context);
    }
    _patches = composed;
    return composed;
  }

  Map<String, Map<String, Object?>> publish() {
    final Map<String, Map<String, Object?>> composed = composeGraph();
    onPatches?.call(composed);
    return composed;
  }

  void tick(double delta) {
    final MotionPathTrigger? currentTrigger = trigger;
    final double span = duration <= 0 ? 1 : duration;
    _elapsed += delta;
    if (currentTrigger != null) {
      seek(currentTrigger.progressAt(_elapsed, span));
    } else {
      progress = (_elapsed / span).clamp(0.0, 1.0).toDouble();
      _seekTracks(_elapsed);
    }
    publish();
    if (progress >= 1 &&
        (currentTrigger == null || currentTrigger.isFinished(_elapsed, span))) {
      pause();
    }
  }

  /// Rewinds the trigger clock without touching authored data.
  void restart() {
    _elapsed = 0;
    progress = 0;
    _seekTracks(0);
  }

  void dispose() {
    onPatches = null;
    for (final MotionPathTrackRuntime track in tracks) track.dispose();
    tracks.clear();
    graph = null;
    playing = false;
    _patches = const <String, Map<String, Object?>>{};
  }
}
