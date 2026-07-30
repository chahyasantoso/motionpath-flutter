import '../contract/motionpath_types.dart';

class ObservationNode {
  const ObservationNode(this.id);
  final String id;
}

class ObservationEdge {
  const ObservationEdge({required this.source, required this.target, this.role = 'output', this.inputKey});

  /// Track that is observed.
  final String source;

  /// Track that declared the observation.
  final String target;

  /// Either `input` or `output`.
  final String role;

  /// Patch key the observed data is delivered under for `input` edges.
  ///
  /// This is the authored `observes[].target`, for example `parentWorld`. It
  /// falls back to [source] so older callers keep working.
  final String? inputKey;
}

class ObservationGraph {
  const ObservationGraph({required this.nodes, required this.edges, required this.order, required this.errors});
  final List<ObservationNode> nodes;
  final List<ObservationEdge> edges;
  final List<String> order;
  final List<MotionPathDiagnostic> errors;
  bool get isValid => errors.isEmpty;
}

ObservationGraph normalizeObservationGraph(MotionPathMotion motion) {
  final diagnostics = <MotionPathDiagnostic>[];
  final nodes = <ObservationNode>[];
  final nodeIds = <String>{};
  final edges = <ObservationEdge>[];
  final edgeKeys = <String>{};

  for (final track in motion.tracks) {
    if (!nodeIds.add(track.id)) {
      diagnostics.add(MotionPathDiagnostic(path: 'tracks.${track.id}', code: 'duplicate-node', message: 'Track id is duplicated.'));
    } else {
      nodes.add(ObservationNode(track.id));
    }
  }

  for (final track in motion.tracks) {
    for (var index = 0; index < track.observes.length; index++) {
      final observation = track.observes[index];
      final source = observation['source'];
      final target = observation['target'];
      final role = observation['role'] ?? 'output';
      final path = 'tracks.${track.id}.observes[$index]';
      if (source is! String || !nodeIds.contains(source)) {
        diagnostics.add(MotionPathDiagnostic(path: '$path.source', code: 'missing-source', message: 'Observation source must reference a track in this motion.'));
        continue;
      }
      if (target is! String || target.isEmpty) {
        diagnostics.add(MotionPathDiagnostic(path: '$path.target', code: 'invalid-target', message: 'Observation target must be a non-empty string.'));
        continue;
      }
      if (role is! String || (role != 'input' && role != 'output')) {
        diagnostics.add(MotionPathDiagnostic(path: '$path.role', code: 'invalid-role', message: 'Role must be input or output.'));
        continue;
      }
      if (source == track.id) {
        diagnostics.add(MotionPathDiagnostic(path: path, code: 'self-cycle', message: 'A track cannot observe itself.'));
        continue;
      }
      final key = '${track.id}|$source|$target|$role';
      if (!edgeKeys.add(key)) {
        diagnostics.add(MotionPathDiagnostic(path: path, code: 'duplicate-edge', message: 'Observation edge is duplicated.'));
        continue;
      }
      edges.add(ObservationEdge(source: source, target: track.id, role: role, inputKey: target));
    }
  }

  final adjacency = <String, List<String>>{for (final node in nodes) node.id: <String>[]};
  final indegree = <String, int>{for (final node in nodes) node.id: 0};
  for (final edge in edges) {
    adjacency[edge.source]!.add(edge.target);
    indegree[edge.target] = indegree[edge.target]! + 1;
  }

  final queue = <String>[for (final node in nodes) if (indegree[node.id] == 0) node.id];
  final order = <String>[];
  for (var cursor = 0; cursor < queue.length; cursor++) {
    final current = queue[cursor];
    order.add(current);
    for (final next in adjacency[current]!) {
      indegree[next] = indegree[next]! - 1;
      if (indegree[next] == 0) queue.add(next);
    }
  }
  if (order.length != nodes.length) {
    diagnostics.add(const MotionPathDiagnostic(path: 'tracks', code: 'cycle', message: 'Observation graph contains a cycle.'));
  }

  return ObservationGraph(
    nodes: List.unmodifiable(nodes),
    edges: List.unmodifiable(edges),
    order: List.unmodifiable(order),
    errors: List.unmodifiable(diagnostics),
  );
}
