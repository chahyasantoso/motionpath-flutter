import '../contract/motionpath_types.dart';
import '../graph/observation_graph.dart';
import '../interpolation/interpolator.dart';
import '../plugins/motionpath_plugin.dart';
import 'motion.dart';
import 'track.dart';
import 'trigger.dart';

/// Owns a loaded project and every runtime object created from it.
class MotionPathEngine {
  MotionPathEngine({MotionPathPluginRegistry? registry})
      : registry = registry ?? MotionPathPluginRegistry();

  final MotionPathPluginRegistry registry;
  MotionPathProject? project;
  final Map<String, MotionPathMotionRuntime> _mounted = <String, MotionPathMotionRuntime>{};
  Iterable<MotionPathMotionRuntime> get mounted => _mounted.values;
  void loadProject(MotionPathProject nextProject) => project = nextProject;
  MotionPathMotionRuntime? motionById(String id) => _mounted[id];

  MotionPathMotionRuntime mountMotion(String id) {
    final MotionPathProject? loaded = project;
    if (loaded == null) throw StateError('No project loaded.');
    final MotionPathMotion? source = loaded.motionById(id);
    if (source == null) throw StateError('Motion not found: $id');
    final ObservationGraph graph = normalizeObservationGraph(source);
    if (!graph.isValid) throw MotionPathValidationException(graph.errors);
    final List<MotionPathTrackRuntime> runtimeTracks = <MotionPathTrackRuntime>[];
    double longest = 0;
    for (final MotionPathTrack track in source.tracks) {
      final Map<String, List<MotionPathStop>> properties = propertiesFromTrack(track);
      final List<MotionPathPlugin> plugins = registry.resolve(properties.keys);
      assertOutputCompatibility(track.id, plugins);
      final double trackDuration = track.duration?.toDouble() ?? 0;
      if (trackDuration > longest) longest = trackDuration;
      runtimeTracks.add(MotionPathTrackRuntime(
        track.id,
        properties: properties,
        plugins: plugins,
        duration: trackDuration,
      ));
    }
    final MotionPathTrigger trigger = MotionPathTrigger.fromJson(source.trigger);
    final MotionPathMotionRuntime runtime = MotionPathMotionRuntime(
      id: id,
      tracks: runtimeTracks,
      trigger: trigger,
      duration: longest > 0 ? longest : 1,
      stagger: source.stagger,
    );
    runtime.prepare(graph);
    runtime.playing = trigger.autoplay;
    _mounted[id] = runtime;
    return runtime;
  }

  void tick(double delta) {
    for (final MotionPathMotionRuntime runtime in List<MotionPathMotionRuntime>.of(_mounted.values)) {
      if (!runtime.playing) continue;
      runtime.tick(delta);
    }
  }

  void unmount(MotionPathMotionRuntime runtime) {
    if (_mounted[runtime.id] != runtime) return;
    runtime.dispose();
    _mounted.remove(runtime.id);
  }

  void destroy() {
    for (final MotionPathMotionRuntime runtime in _mounted.values) runtime.dispose();
    _mounted.clear();
    project = null;
  }
}
