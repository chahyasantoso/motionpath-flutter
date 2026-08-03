# Renderer system PRD

## Summary

Formalize MotionPath rendering as a composable multi-renderer system. One runtime publishes renderer-neutral patches once; multiple renderers consume the same frame for different entities or surfaces. Renderers are selected per visual entity, not globally.

A scene may combine a canvas background, widget-based interactive actors, render-object list items, and an overlay Hero flight while preserving one source of motion truth.

## Problem

The repository already has painters, patch views, spawn views, transforms, depth, image/filter consumers, and lifecycle-aware scheduling. Those capabilities are useful but currently read as separate adapters rather than one deliberate contract. Without formalization, plugin support will become inconsistent, Hero integration will be bolted on, and every new renderer will invent its own lifecycle, hit testing, semantics, and capability rules.

## Goals

- Define a stable renderer-neutral frame and entity identity contract.
- Allow several renderer types to consume the same runtime frame.
- Make renderer capabilities explicit per plugin output.
- Support Canvas, Widget, RenderObject, Overlay, and Headless renderers.
- Preserve one scheduler, one runtime state, and deterministic patch ordering.
- Provide clear behavior for unsupported fields, missing assets, hit testing, semantics, reduced motion, and disposal.
- Make Hero flights a first-class OverlayRenderer integration without replacing Flutter Hero pairing.

## Non-goals

- A universal renderer that supports every plugin.
- Replacing Flutter's widget, sliver, Hero, or semantics systems.
- Making Canvas and Widget rendering interchangeable at the pixel level.
- Turning MotionPath into a complete game engine.
- Adding a second animation loop per renderer.

## Core concepts

### Runtime frame

A runtime frame contains a monotonically identified frame/sample, playhead information, and immutable patches keyed by stable entity ID. Renderers never mutate runtime patches.

### Entity identity

Every visible entity needs a stable ID independent of its widget instance, list index, or render target. Identity enables renderer handoff, Hero promotion, spawn/reflow, caching, hit testing, and deterministic tests.

### Renderer instance

A renderer instance binds a set of entity IDs to one presentation target. It owns target-specific resources and subscriptions, but not motion truth or engine time.

### Capability declaration

Each renderer declares the patch fields and plugin outputs it can consume. Unsupported output must be reported through diagnostics or an explicit fallback policy, never silently ignored.

## Renderer matrix

| Renderer | Best for | Owns | Must support first |
|---|---|---|---|
| CanvasRenderer | Dense particles, bullets, maps, charts, background scenes | Canvas paint, batching, canvas hit testing | transforms, opacity, images, basic filters |
| WidgetRenderer | Interactive Flutter subtrees, forms, semantic content | Widget composition and state | transforms, opacity, semantics, gestures |
| RenderObjectRenderer | High-volume transformed children, path lists, layout-aware hit testing | Layout/paint invalidation and layers | transforms, depth, hit testing, repaint isolation |
| OverlayRenderer | Hero flights, drag previews, route transitions, portals | Overlay entry and flight lifecycle | transforms, opacity, route progress, handoff |
| HeadlessRenderer | Tests, sampling, recording, export, server-side validation | Deterministic output snapshots | all data fields without Flutter objects |

## Composition rules

1. One runtime may feed many renderer instances.
2. One entity uses one active renderer at a time unless explicitly duplicated for a mirror/preview.
3. Renderer handoff must preserve entity identity and current sampled state.
4. Renderer order is separate from runtime graph order. Runtime resolves data; scene composition resolves visual layering.
5. A renderer may consume only the capabilities it declares.
6. No renderer creates a ticker, timer, or competing playhead.
7. Renderers may request repaint, relayout, or resource work, but they may not mutate engine state during paint.

## Plugin compatibility

Plugins should declare output metadata and renderer requirements. Examples:

- Path and transform outputs: all visual renderers.
- Opacity: all visual renderers.
- Image sequence: Canvas, Widget, RenderObject, and Overlay with an image resolver.
- Blur/filter: Canvas and RenderObject first; Widget through explicit wrappers where possible.
- CSS variables: Widget or a platform adapter, not Canvas by default.
- Spawner: scene composition/runtime layer, not a paint primitive.
- Custom geometry: Canvas or a plugin-specific RenderObject.

The compatibility decision must be explicit: consume, degrade, fallback, or reject.

## Hero support

Add a `MotionPathHero` adapter that uses Flutter Hero for tag pairing, overlay placement, placeholders, route lifecycle, and reverse gestures. MotionPath supplies the in-flight playhead and composed plugin patches through an OverlayRenderer.

The API should accept a project-backed motion/runtime, not only a path. The Hero flight can therefore use path, scale, opacity, image sequence, filters, dependent tracks, or any plugin with an overlay capability.

```dart
MotionPathHero.runtime(
  tag: product.id,
  motion: heroMotion,
  trackId: 'product-flight',
  child: ProductThumbnail(product),
)
```

## Accessibility and reduced motion

Motion must never be the only state signal. Preserve logical semantics and focus order even when entities move visually. Add a reduced-motion policy that can snap to the destination state, reduce transforms, or keep only essential continuity. The policy belongs above individual renderers so Canvas, Widget, RenderObject, and Overlay agree.

## Success criteria

- A single runtime frame can drive at least two renderer types in one scene.
- Capability mismatches produce actionable diagnostics.
- Entity handoff from Widget to Overlay preserves visual state and identity.
- Hero transitions support reverse and user-controlled route gestures.
- Canvas and RenderObject paths do not rebuild widget subtrees per frame.
- Headless snapshots match runtime samples used by Flutter renderers.
- Disposal leaves no renderer subscriptions, overlay entries, image handles, or ticker leaks.
