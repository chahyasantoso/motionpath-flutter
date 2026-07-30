import '../graph/observation_graph.dart';
import 'track.dart';
import 'trigger.dart';

/// A mounted motion: one trigger, one playhead, and the tracks that share it.
class MotionPathMotionRuntime {
  MotionPathMotionRuntime({
    required this.id,
    required this.tracks,
    this.trigger,
    this.duration = 1,
    this.stagger = 0,
  });

  final String id;
  final List<MotionPathTrackRuntime> tracks;
  final MotionPathTrigger? trigger;
  double duration;
  final double stagger;
  double progress = 0;
  bool playing = false;
  ObservationGraph? graph;
  void Function(Map<String, Map<String, Object?>> patches)? onPatches;
  double _elapsed = 0;
  Map<String, Map<String, Object?>> _patches = const <String, Map<String, Object?>>{};

  Map<String, Map<String, Object?>> get patches => _patches;
  List<String> get graphOrder => graph == null ? const <String>[] : List<String>.unmodifiable(graph!.order);

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
      for (int index = 0; index < order.length; index++) {
        indexById[order[index]] = index;
      }
    };
    for (final MotionPathTrackRuntime track in tracks) {
      final double delay = stagger > 0 ? (indexById[track.id] ?? 0) * stagger : 0;
      final double span = track.duration > 0 ? track.duration : (duration <= 0 ? 1 : duration);
      final double local = (elapsed - delay) / span;
      track.seek(local.clamp(0.0, 1.0).toDouble());
    }
  }

  Map<String, Map<String, Object?>> composeGraph() {
    final ObservationGraph? current = graph;
    if (current == null) return const <String, Map<String, Object?>>{};
    final Map<String, MotionPathTrackRuntime> byId = <String, MotionPathTrackRuntime>{
      for (final MotionPathTrackRuntime track in tracks) track.id: track,
    };
    final Map<MotionPathTrackRuntime, Map<String, Object?>?> context = <MotionPathTrackRuntime, Map<String, Object?>?>{};
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
    if (currentTrigger == null) {
      progress = (_elapsed / span).clamp(0.0, 1.0).toDouble();
      _seekTracks(_elapsed);
    } else {
      progress = currentTrigger.progressAt(_elapsed, span);
      if (stagger > 0) {
        _seekTracks(progress * span);
      } else {
        for (final MotionPathTrackRuntime track in tracks) {
          track.seek(progress);
        }
      }
    }
    publish();
    if (progress >= 1 && (currentTrigger == null || currentTrigger.isFinished(_elapsed, span))) {
      pause();
    }
  }

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
