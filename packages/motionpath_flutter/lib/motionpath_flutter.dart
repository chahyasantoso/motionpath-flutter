/// Public entrypoint for Flutter scheduling and rendering adapters.
///
/// The adapter converts Flutter time or scroll input into engine ticks and
/// seeks, then hands renderer-neutral patches to painters. It never owns engine
/// behaviour and never creates a second frame source.
library motionpath_flutter;

/// Re-exports the renderer-neutral engine contract for Flutter examples and
/// applications that use both packages together. The implementation remains in
/// `motionpath_core`; this is only a convenient, stable import boundary.
export 'package:motionpath_core/motionpath_core.dart';

export 'src/bindings/motion_path_scroll_binding.dart';
export 'src/bindings/motion_path_viewport_binding.dart';
export 'src/consumers/motion_path_patch_consumers.dart';
export 'src/controllers/motion_path_patch_controller.dart';
export 'src/controllers/motion_path_spawn_controller.dart';
export 'src/controllers/motion_path_spawn_ticker_binding.dart';
export 'src/motionpath_flutter_placeholder.dart';
export 'src/painters/motion_path_patch_painter.dart';
export 'src/painters/motion_path_rig_painter.dart';
export 'src/scene/motion_path_patch_source.dart';
export 'src/scene/motion_path_patch_view.dart';
export 'src/scene/motion_path_walker_scene.dart';
export 'src/scroll/motion_path_scroll_driver.dart';
export 'src/ticker/motion_path_ticker_driver.dart';
