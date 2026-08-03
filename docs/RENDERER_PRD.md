# Renderer system PRD

## Summary

Formalize MotionPath rendering as a composable multi-renderer system. One validated runtime publishes renderer-neutral patches once; multiple renderer instances consume the same frame for different visual entities. Renderers are selected per entity, not globally.

## User problem

The current system can render patches through painters, widgets, and spawned views, but the capability boundary is implicit. That makes it unclear which plugins work in which target, how Canvas, widget, render-object, and overlay output can coexist, and how Hero flights or dense game scenes should share one runtime.

## Product promise

Authors define motion once. Applications choose the best presentation target for each entity without duplicating motion logic or creating one runtime per renderer.

## Goals

- Define a stable renderer capability contract.
- Support Canvas, Widget, RenderObject, Overlay, and Headless/recording targets.
- Allow several renderer instances to subscribe to one runtime frame.
- Keep plugin composition in core and presentation concerns in adapters.
- Make unsupported plugin fields explicit through capability checks and diagnostics.
- Preserve Flutter semantics, hit testing, lifecycle, and performance expectations.
- Support Hero-style route flights without replacing Flutter Hero pairing and overlay ownership.

## Non-goals

- One universal renderer that can consume every plugin.
- Replacing Flutter's layout, Navigator, Hero, or game loop.
- Turning Canvas into a semantic widget tree.
- Creating one Motion runtime per visible item or renderer.
- Hiding capability differences behind silent visual degradation.

## Renderer targets

### CanvasRenderer

For dense particles, bullets, maps, graph edges, effects, and low-overhead scenes. Consumes transform, opacity, color, image, filter, and custom geometry fields where supported. Owns paint caching, clipping, z ordering, and optional canvas hit testing.

### WidgetRenderer

For normal Flutter subtrees that need gestures, semantics, focus, inherited themes, and accessibility. Uses stable child identity and patch-driven repaint/transform wrappers. It is the easiest integration target, not the cheapest for thousands of entities.

### RenderObjectRenderer

For layout-aware, high-frequency children such as path lists, dynamic actors, and complex hit testing. Updates paint and compositing state without rebuilding widget subtrees. This is the performance path for `MotionPathListView`.

### OverlayRenderer

For Hero flights, route transitions, drag previews, tooltips, sheets, and selected entities promoted above normal layout. Flutter owns overlay insertion and route pairing; MotionPath owns the sampled choreography.

### HeadlessRenderer

For deterministic tests, golden sampling, export/recording, telemetry, and future non-Flutter adapters. Produces sampled frames or validated capability reports without painting.

## Core contract

```dart
abstract class MotionPathRenderer {
  RendererCapabilities get capabilities;
  void attach(MotionPathFrameSource source);
  void detach();
  void dispose();
}

class RendererCapabilities {
  final Set<String> pluginNames;
  final Set<String> outputKeys;
  final bool supportsSemantics;
  final bool supportsHitTesting;
  final bool supportsOverlay;
}
```

The exact API may change, but the rule should not: plugins emit patches, renderers declare what they consume, and the runtime never imports Flutter presentation types.

## Frame and subscription model

- One `MotionPathEngine` or `MotionPathMotionRuntime` owns truth.
- A frame is immutable and versioned.
- Subscribers filter by entity IDs and output interest.
- Renderers may share a source and repaint independently.
- Attach/detach is idempotent.
- Renderer disposal never destroys a shared runtime unless it owns that runtime explicitly.

## Plugin compatibility

Every plugin should declare output metadata and renderer requirements. A renderer must choose one of three explicit outcomes:

1. consume the field;
2. report unsupported capability before mounting;
3. intentionally ignore a nonessential field with diagnostics in debug mode.

Required compatibility tests should cover path, image sequence, CSS variable, filter, overlay, spawner, and forward-kinematics outputs across relevant renderers.

## Hero integration

Add `MotionPathHero` as an adapter around Flutter `Hero`, not a replacement. Flutter continues to pair tags, manage the Navigator overlay, placeholders, route lifecycle, and reverse gestures. The adapter supplies a MotionPath-driven in-flight child or render target that can consume any supported plugin output, not only path geometry.

The adapter must handle source/destination bounds, inherited themes, GlobalKey restrictions, direction reversal, cancellation, and route disposal. Unsupported plugins should fail clearly rather than produce a broken flight.

## Accessibility and reduced motion

Renderers must preserve logical semantics and focus order where possible. Motion cannot be the only communication channel. Add a reduced-motion policy that can snap to the final state, remove rotation/depth effects, or use a short opacity transition while preserving the same semantic state change.

## Acceptance criteria

- Two renderer types consume the same frame and remain synchronized.
- A plugin capability mismatch is diagnosable before or during mount.
- Canvas and widget outputs can coexist in one scene.
- RenderObjectRenderer can update visible list children without full widget rebuilds.
- OverlayRenderer supports a custom MotionPathHero flight.
- Headless sampling matches Flutter renderer inputs for the same fixture.
- Attach, detach, route cancellation, and shared-runtime disposal are covered by tests.
