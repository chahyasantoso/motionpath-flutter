import 'package:meta/meta.dart';

import '../contract/motionpath_types.dart';

/// A node in the compiled observation graph. One node is one track.
@immutable
class ObservationNode {
  /// Creates a node.
  const ObservationNode(this.id, {this.index = 0});

  /// Track id.
  final String id;

  /// Authored position of the track inside its motion.
  final int index;

  @override
  bool operator ==(Object other) =>
      other is ObservationNode && other.id == id && other.index == index;

  @override
  int get hashCode => Object.hash(id, index);
}

/// A dependency edge declared through `observes`.
///
/// An `input` edge wraps the source patch under [input] before the target's
/// plugins compose. An `output` edge merges the source patch over the target's
/// final patch.
@immutable
class ObservationEdge {
  /// Creates an edge.
  const ObservationEdge({
    required this.source,
    required this.target,
    this.role = 'output',
    this.input,
    this.path = '',
  });

  /// Observed track id.
  final String source;

  /// Observing track id.
  final String target;

  /// Either `input` or `output`.
  final String role;

  /// Key the source patch is wrapped under, for `input` edges only.
  final String? input;

  /// JSON path of the authored observation.
  final String path;

  /// Whether this edge feeds the target's plugins.
  bool get isInput => role == 'input';

  @override
  bool operator ==(Object other) =>
      other is ObservationEdge &&
      other.source == source &&
      other.target == target &&
      other.role == role &&
      other.input == input;

  @override
  int get hashCode => Object.hash(source, target, role, input);
}

/// Immutable, JSON-safe observation graph IR.
@immutable
class ObservationGraph {
  /// Creates a graph.
  const ObservationGraph({
    required this.nodes,
    required this.edges,
    required this.order,
    required this.errors,
  });

  /// Every valid track node.
  final List<ObservationNode> nodes;

  /// Every valid dependency edge.
  final List<ObservationEdge> edges;

  /// Stable parent-before-child composition order.
  final List<String> order;

  /// Diagnostics collected while normalizing.
  final List<MotionPathDiagnostic> errors;

  /// Whether the graph is safe to mount.
  bool get isValid =>
      errors.every((MotionPathDiagnostic error) => !error.isFatal);

  /// Input edges pointing at [trackId].
  Iterable<ObservationEdge> inputsFor(String trackId) => edges.where(
    (ObservationEdge edge) => edge.target == trackId && edge.isInput,
  );

  /// Output edges pointing at [trackId].
  Iterable<ObservationEdge> outputsFor(String trackId) => edges.where(
    (ObservationEdge edge) => edge.target == trackId && !edge.isInput,
  );
}

/// Returns a copy of the compiled order.
List<String> topologicalTrackOrder(ObservationGraph graph) =>
    List<String>.of(graph.order);

/// Normalizes a motion's authored observations into an immutable graph IR.
ObservationGraph normalizeObservationGraph(MotionPathMotion motion) {
  final List<MotionPathDiagnostic> errors = <MotionPathDiagnostic>[];
  final List<ObservationNode> nodes = <ObservationNode>[];
  final Map<String, int> nodeIndexes = <String, int>{};

  for (int index = 0; index < motion.tracks.length; index++) {
    final String id = motion.tracks[index].id;
    if (id.isEmpty) {
      errors.add(
        MotionPathDiagnostic(
          path: 'tracks[$index].id',
          code: 'track-observations',
          message: 'Track id must be a non-empty string.',
        ),
      );
      continue;
    }
    if (nodeIndexes.containsKey(id)) {
      errors.add(
        MotionPathDiagnostic(
          path: 'tracks[$index].id',
          code: 'track-observations-duplicate-node',
          message: "Track '$id' is declared more than once.",
        ),
      );
      continue;
    }
    nodeIndexes[id] = index;
    nodes.add(ObservationNode(id, index: index));
  }

  final List<ObservationEdge> edges = <ObservationEdge>[];
  final Set<String> edgeKeys = <String>{};
  for (int trackIndex = 0; trackIndex < motion.tracks.length; trackIndex++) {
    final MotionPathTrack track = motion.tracks[trackIndex];
    for (int edgeIndex = 0; edgeIndex < track.observes.length; edgeIndex++) {
      final Map<String, Object?> observation = track.observes[edgeIndex];
      final String path = 'tracks[$trackIndex].observes[$edgeIndex]';
      if (observation.isEmpty) {
        errors.add(
          MotionPathDiagnostic(
            path: path,
            code: 'track-observations',
            message: 'Observation must be an object.',
          ),
        );
        continue;
      }
      final String targetNode = track.id;
      if (!nodeIndexes.containsKey(targetNode)) {
        errors.add(
          MotionPathDiagnostic(
            path: '$path.target',
            code: 'track-observations',
            message: "Unknown target track '$targetNode'.",
          ),
        );
        continue;
      }
      final Object? source = observation['source'];
      if (source is! String || !nodeIndexes.containsKey(source)) {
        errors.add(
          MotionPathDiagnostic(
            path: '$path.source',
            code: 'track-observations',
            message: "Unknown source track '$source'.",
          ),
        );
        continue;
      }
      if (source == targetNode) {
        errors.add(
          MotionPathDiagnostic(
            path: '$path.source',
            code: 'track-observations-cycle',
            message: "Track '$targetNode' cannot observe itself.",
          ),
        );
        continue;
      }
      final Object? rawRole = observation['role'];
      final String role = rawRole == null
          ? 'output'
          : (rawRole is String ? rawRole : '');
      if (role != 'input' && role != 'output') {
        errors.add(
          MotionPathDiagnostic(
            path: '$path.role',
            code: 'track-observations',
            message: "Observation role must be 'input' or 'output'.",
          ),
        );
        continue;
      }
      final Object? target = observation['target'];
      String? inputKey;
      if (role == 'input') {
        if (target is! String || target.isEmpty) {
          errors.add(
            MotionPathDiagnostic(
              path: '$path.target',
              code: 'track-observations',
              message: 'Input observations require a non-empty target.',
            ),
          );
          continue;
        }
        inputKey = target;
      } else if (target != null) {
        errors.add(
          MotionPathDiagnostic(
            path: '$path.target',
            code: 'track-observations',
            message: 'Output observations cannot define target.',
          ),
        );
        continue;
      }
      final String key = '$source|$targetNode|$role|${inputKey ?? ''}';
      if (!edgeKeys.add(key)) {
        errors.add(
          MotionPathDiagnostic(
            path: path,
            code: 'track-observations-duplicate-edge',
            message:
                "Duplicate observation edge from '$source' to '$targetNode'.",
          ),
        );
        continue;
      }
      edges.add(
        ObservationEdge(
          source: source,
          target: targetNode,
          role: role,
          input: inputKey,
          path: path,
        ),
      );
    }
  }

  final Map<String, List<ObservationEdge>> outgoing =
      <String, List<ObservationEdge>>{
        for (final ObservationNode node in nodes) node.id: <ObservationEdge>[],
      };
  final Map<String, int> indegree = <String, int>{
    for (final ObservationNode node in nodes) node.id: 0,
  };
  for (final ObservationEdge edge in edges) {
    outgoing[edge.source]!.add(edge);
    indegree[edge.target] = indegree[edge.target]! + 1;
  }

  final List<String> queue = <String>[
    for (final ObservationNode node in nodes)
      if (indegree[node.id] == 0) node.id,
  ];
  final List<String> order = <String>[];
  while (queue.isNotEmpty) {
    final String id = queue.removeAt(0);
    order.add(id);
    for (final ObservationEdge edge in outgoing[id]!) {
      final int remaining = indegree[edge.target]! - 1;
      indegree[edge.target] = remaining;
      if (remaining != 0) {
        continue;
      }
      final int insertAt = queue.indexWhere(
        (String queued) => nodeIndexes[queued]! > nodeIndexes[edge.target]!,
      );
      if (insertAt == -1) {
        queue.add(edge.target);
      } else {
        queue.insert(insertAt, edge.target);
      }
    }
  }
  if (order.length != nodes.length) {
    errors.add(
      const MotionPathDiagnostic(
        path: 'tracks',
        code: 'track-observations-cycle',
        message: 'Observation graph contains a cycle.',
      ),
    );
  }

  return ObservationGraph(
    nodes: List<ObservationNode>.unmodifiable(nodes),
    edges: List<ObservationEdge>.unmodifiable(edges),
    order: List<String>.unmodifiable(order),
    errors: List<MotionPathDiagnostic>.unmodifiable(errors),
  );
}
