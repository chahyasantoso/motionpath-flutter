/// Public entrypoint for the pure Dart MotionPath v4 animation engine.
///
/// This library never imports Flutter, touches a platform API, or schedules a
/// frame. Rendering and scheduling belong to the adapter.
library motionpath_core;

export 'src/composition/compose_patch.dart';
export 'src/composition/graph_publisher.dart';
export 'src/contract/motionpath_types.dart';
export 'src/graph/observation_graph.dart';
export 'src/interpolation/easing.dart';
export 'src/interpolation/interpolator.dart';
export 'src/math/fk_math.dart';
export 'src/plugins/motionpath_plugin.dart';
export 'src/runtime/engine.dart';
export 'src/runtime/motion.dart';
export 'src/runtime/track.dart';
export 'src/runtime/trigger.dart';
export 'src/validation/validate_project.dart';
