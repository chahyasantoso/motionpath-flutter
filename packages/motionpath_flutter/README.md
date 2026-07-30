# motionpath_flutter

Flutter scheduling and rendering adapters for the MotionPath v4 engine. It connects one Flutter ticker or caller-owned scroll samples to the pure Dart core, then exposes renderer-neutral patches to painters and host widgets.

Start with [`docs/API.md`](../../docs/API.md) and [`docs/MIGRATION.md`](../../docs/MIGRATION.md). Dispose route-owned bindings, keep one ticker per engine, and let the host own actual layout and pinning.
