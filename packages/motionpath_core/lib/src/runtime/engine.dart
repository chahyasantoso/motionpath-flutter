import '../contract/motionpath_types.dart';
import '../graph/observation_graph.dart';
import 'motion.dart';
import 'track.dart';

class MotionPathEngine {
  MotionPathProject? project;
  final Map<String, MotionPathMotionRuntime> _mounted = <String, MotionPathMotionRuntime>{};

  void loadProject(MotionPathProject nextProject) => project = nextProject;

  MotionPathMotionRuntime mountMotion(String id) {
    final source = project?.motions.firstWhere((motion) => motion.id == id);
    if (source == null) throw StateError('Motion not found: $id');
    final runtimeTracks = source.tracks.map((track) => MotionPathTrackRuntime(track.id, stops: stopsFromTrack(track))).toList();
    final runtime = MotionPathMotionRuntime(id: id, tracks: runtimeTracks);
    runtime.prepare(normalizeObservationGraph(source));
    _mounted[id] = runtime;
    return runtime;
  }

  void tick(double delta) {
    for (final runtime in _mounted.values) {
      if (!runtime.playing) continue;
      runtime.tick(delta);
    }
  }

  void unmount(MotionPathMotionRuntime runtime) {
    runtime.dispose();
    _mounted.remove(runtime.id);
  }

  void destroy() {
    for (final runtime in _mounted.values) runtime.dispose();
    _mounted.clear();
    project = null;
  }
}
