import 'package:motionpath_core/motionpath_core.dart';
import 'package:test/test.dart';

MotionPathProject _project() => const MotionPathProject(
  schemaVersion: 4,
  projectId: 'ownership',
  motions: <MotionPathMotion>[
    MotionPathMotion(
      id: 'hero',
      trigger: <String, Object?>{'type': 'manual'},
      tracks: <MotionPathTrack>[MotionPathTrack(id: 'track')],
    ),
  ],
);

void main() {
  test('track lifecycle callbacks reject double wiring in release-safe code', () {
    final MotionPathTrackRuntime track = MotionPathTrackRuntime('parent');
    void first(MotionPathTrackRuntime child, double offset) {}
    void second(MotionPathTrackRuntime child, double offset) {}
    track.onChildSpawned = first;
    expect(() => track.onChildSpawned = second, throwsA(isA<StateError>()));
    track.onChildSpawned = null;
    track.onChildSpawned = second;
  });

  test('motion preparation rejects duplicate graph wiring', () {
    final MotionPathEngine engine = MotionPathEngine()..loadProject(_project());
    final MotionPathMotionRuntime motion = engine.mountMotion('hero');
    final ObservationGraph graph = normalizeObservationGraph(_project().motions.single);
    expect(() => motion.prepare(graph), throwsA(isA<StateError>()));
    engine.destroy();
  });

  test('motion preparation rejects an invalid graph before wiring', () {
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(id: 'hero', tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('track')]);
    const ObservationGraph invalid = ObservationGraph(nodes: <ObservationNode>[], edges: <ObservationEdge>[], order: <String>[], errors: <MotionPathDiagnostic>[MotionPathDiagnostic(path: 'tracks', code: 'track-observations', message: 'invalid graph')]);
    expect(() => motion.prepare(invalid), throwsA(isA<MotionPathValidationException>()));
    expect(motion.graph, isNull);
  });

  test('direct input observation wiring rejects a missing key', () {
    final MotionPathTrackRuntime target = MotionPathTrackRuntime('target');
    final MotionPathTrackRuntime source = MotionPathTrackRuntime('source');
    expect(() => target.observe(source, role: 'input'), throwsA(isA<ArgumentError>()));
    expect(() => target.observe(source, role: 'sideways'), throwsA(isA<ArgumentError>()));
    expect(() => target.observe(source, role: 'output', input: 'x'), throwsA(isA<ArgumentError>()));
    expect(target.observations, isEmpty);
  });

  test('runtime boundaries reject non-finite values', () {
    expect(() => MotionPathTrackRuntime('track', duration: double.nan), throwsA(isA<ArgumentError>()));
    expect(() => MotionPathMotionRuntime(id: 'motion', tracks: <MotionPathTrackRuntime>[], duration: double.infinity), throwsA(isA<ArgumentError>()));
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(id: 'motion', tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('track')]);
    expect(() => motion.seek(double.nan), throwsA(isA<ArgumentError>()));
    expect(() => motion.tick(double.infinity), throwsA(isA<ArgumentError>()));
    expect(() => motion.tracks.single.seek(double.nan), throwsA(isA<ArgumentError>()));
  });

  test('runtime ownership rejects duplicate track ids', () {
    expect(() => MotionPathMotionRuntime(id: 'motion', tracks: <MotionPathTrackRuntime>[MotionPathTrackRuntime('same'), MotionPathTrackRuntime('same')]), throwsA(isA<StateError>()));
  });

  test('engine rejects duplicate mounts instead of replacing live runtime', () {
    final MotionPathEngine engine = MotionPathEngine()..loadProject(_project());
    final MotionPathMotionRuntime original = engine.mountMotion('hero');
    expect(() => engine.mountMotion('hero'), throwsA(isA<StateError>()));
    expect(engine.motionById('hero'), same(original));
    expect(original.tracks.single.isDisposed, isFalse);
    engine.destroy();
  });

  test('engine rejects project replacement while a motion is mounted', () {
    final MotionPathEngine engine = MotionPathEngine()..loadProject(_project());
    engine.mountMotion('hero');
    expect(() => engine.loadProject(_project()), throwsA(isA<StateError>()));
    engine.destroy();
  });

  test('motion owns an immutable track view and dispose preserves caller list', () {
    final List<MotionPathTrackRuntime> tracks = <MotionPathTrackRuntime>[MotionPathTrackRuntime('track')];
    final MotionPathMotionRuntime motion = MotionPathMotionRuntime(id: 'hero', tracks: tracks);
    expect(motion.tracks, isA<List<MotionPathTrackRuntime>>());
    expect(() => motion.tracks.clear(), throwsUnsupportedError);
    motion.dispose();
    expect(tracks, hasLength(1));
    expect(tracks.single.isDisposed, isTrue);
  });
}
