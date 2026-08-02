import '../contract/motionpath_types.dart';
import '../graph/observation_graph.dart';
import 'track.dart';
import 'trigger.dart';

/// A mounted motion: one trigger, one playhead, and the tracks that share it.
class MotionPathMotionRuntime {
  MotionPathMotionRuntime({
    required this.id,
    required List<MotionPathTrackRuntime> tracks,
    this.trigger,
    double duration = 1,
    this.stagger = 0,
  })  : tracks = _immutableUniqueTracks(tracks),
        _duration = _finiteNonNegative(duration, 'duration');

  static List<MotionPathTrackRuntime> _immutableUniqueTracks(
    List<MotionPathTrackRuntime> tracks,
  ) {
    final Set<String> ids = <String>{};
    for (final MotionPathTrackRuntime track in tracks) {
      if (!ids.add(track.id)) {
        throw StateError('Motion "${track.id}" contains duplicate track id.');
      }
    }
    return List<MotionPathTrackRuntime>.unmodifiable(tracks);
  }

  static double _finiteNonNegative(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, name, 'must be finite and non-negative');
    }
    return value;
  }

  final String id;
  final List<MotionPathTrackRuntime> tracks;
  final MotionPathTrigger? trigger;
  final double stagger;
  double _duration;
  double _progress = 0;
  bool playing = false;
  bool _completed = false;
  ObservationGraph? graph;
  void Function(Map<String, Map<String, Object?>> patches)? onPatches;

  /// Called once when an advancing motion completes its final cycle.
  ///
  /// Reaching the end while paused does not fire the callback. Calling
  /// [restart] or seeking back below the endpoint arms it for the next run.
  void Function()? onComplete;

  double _elapsed = 0;
  Map<String, Map<String, Object?>> _patches =
      const <String, Map<String, Object?>>{};

  double get duration => _duration;
  set duration(double value) => _duration = _finiteNonNegative(value, 'duration');

  double get progress => _progress;
  set progress(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'progress', 'must be finite');
    }
    _progress = value.clamp(0.0, 1.0).toDouble();
  }

  Map<String, Map<String, Object?>> get patches => _patches;
  List<String> get graphOrder => graph == null
      ? <String>[for (final MotionPathTrackRuntime track in tracks) track.id]
      : List<String>.unmodifiable(graph!.order);

  void prepare(ObservationGraph nextGraph) {
    if (graph != null) {
      throw StateError('Motion "$id" is already prepared.');
    }
    if (!nextGraph.isValid) {
      throw MotionPathValidationException(nextGraph.errors);
    }
    final Map<String, MotionPathTrackRuntime> byId =
        <String, MotionPathTrackRuntime>{
          for (final MotionPathTrackRuntime track in tracks) track.id: track,
        };
    for (final ObservationEdge edge in nextGraph.edges) {
      final MotionPathTrackRuntime? target = byId[edge.target];
      final MotionPathTrackRuntime? source = byId[edge.source];
      if (target == null || source == null) {
        throw StateError(
          'Observation edge references an unknown runtime track: '
          '${edge.source} -> ${edge.target}.',
        );
      }
      target.observe(source, role: edge.role, input: edge.input);
    }
    graph = nextGraph;
  }

  void play() => playing = true;
  void pause() => playing = false;
  void reverse() => seek(1 - progress);

  void seek(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
    progress = value;
    _elapsed = progress * (duration <= 0 ? 1 : duration);
    if (progress < 1) _completed = false;
    _seekTracks(_elapsed);
  }

  void _seekTracks(double elapsed) {
    final List<String> order = graphOrder;
    final Map<String, int> indexById = <String, int>{
      for (int index = 0; index < order.length; index++) order[index]: index,
    };
    for (final MotionPathTrackRuntime track in tracks) {
      final double delay = stagger > 0
          ? (indexById[track.id] ?? 0) * stagger
          : 0;
      final double span = track.duration > 0
          ? track.duration
          : (duration <= 0 ? 1 : duration);
      final double local = (elapsed - delay) / span;
      track.seek(local.clamp(0.0, 1.0).toDouble());
    }
  }

  Map<String, Map<String, Object?>> composeGraph({Set<String>? only}) {
    final List<String> order = graphOrder;
    final Map<String, MotionPathTrackRuntime> byId =
        <String, MotionPathTrackRuntime>{
          for (final MotionPathTrackRuntime track in tracks) track.id: track,
        };
    final Map<MotionPathTrackRuntime, Map<String, Object?>?> context =
        <MotionPathTrackRuntime, Map<String, Object?>?>{};
    final Map<String, Map<String, Object?>> composed =
        <String, Map<String, Object?>>{};
    for (final String trackId in order) {
      if (only != null && !only.contains(trackId)) continue;
      final MotionPathTrackRuntime? track = byId[trackId];
      if (track == null) {
        throw StateError('Graph order references unknown track "$trackId".');
      }
      composed[trackId] = track.compose(context: context);
    }
    if (only == null) _patches = composed;
    return composed;
  }

  Map<String, Map<String, Object?>> publish() {
    final Map<String, Map<String, Object?>> composed = composeGraph();
    onPatches?.call(composed);
    return composed;
  }

  void advance(double delta, {bool publishPatches = true}) {
    if (!delta.isFinite || delta < 0) {
      throw ArgumentError.value(delta, 'delta', 'must be finite and non-negative');
    }
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
        for (final MotionPathTrackRuntime track in tracks) track.seek(progress);
      }
    }
    if (publishPatches) publish();
    final bool finished = progress >= 1 &&
        (currentTrigger == null || currentTrigger.isFinished(_elapsed, span));
    if (finished) {
      pause();
      if (!_completed) {
        _completed = true;
        onComplete?.call();
      }
    }
  }

  /// Advances the playhead by [delta] seconds and publishes the full graph.
  void tick(double delta) => advance(delta);

  void restart() {
    _elapsed = 0;
    progress = 0;
    _completed = false;
    _seekTracks(0);
  }

  void dispose() {
    onPatches = null;
    onComplete = null;
    for (final MotionPathTrackRuntime track in tracks) track.dispose();
    graph = null;
    playing = false;
    _patches = const <String, Map<String, Object?>>{};
  }
}
