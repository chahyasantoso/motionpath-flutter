/// Public entrypoint for Flutter scheduling and rendering adapters.
///
/// The adapter converts Flutter time or scroll input into engine ticks and
/// seeks, then hands renderer-neutral patches to painters. It never owns engine
/// behaviour and never creates a second frame source.
library motionpath_flutter;

export 'src/bindings/motion_path_scroll_binding.dart';
export 'src/controllers/motion_path_patch_controller.dart';
export 'src/motionpath_flutter_placeholder.dart';
export 'src/painters/motion_path_patch_painter.dart';
export 'src/painters/motion_path_rig_painter.dart';
export 'src/ticker/motion_path_ticker_driver.dart';
