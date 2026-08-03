# MotionPath Flutter: use cases and product rationale

## Executive conclusion

MotionPath should make spatial relationships and state changes explicit in Flutter interfaces and small game-like experiences, without forcing teams to choose between expressive motion and native rendering behavior.

Its durable value is not a collection of flashy demos. It is a data-driven system that validates motion, composes dependent tracks, drives them from time or input, publishes immutable patches, and lets multiple renderers present the same state.

## New renderer insight

The renderer system expands the product from a motion adapter into a presentation platform. Canvas, Widget, RenderObject, Overlay, and Headless renderers can work together from one runtime frame. That enables a dense background plus interactive widgets, a lazy path list plus a Hero flight, or a game scene plus inspectable headless replay without duplicating motion logic.

The strongest wedge remains `MotionPathListView.builder`, followed by `MotionPathHero.runtime`. Together they address two common gaps: expressive lazy lists and custom shared-element transitions.

## Problem map

| Problem | Need | MotionPath answer |
|---|---|---|
| Abrupt navigation loses context | Continuity and focus | Overlay renderer and runtime-authored Hero flights |
| Gestures are invisible to first-time users | Preview and cause/effect | Scroll/gesture-bound playheads and composed tracks |
| Feeds and catalogs are visually interchangeable | Spatial emphasis and memory | RenderObject path lists with lazy construction |
| Dense scenes become expensive as widgets | Bounded paint work | Canvas renderer with batching and interest filtering |
| Interactive children need native semantics | Real Flutter behavior | Widget and RenderObject renderers |
| Designers and engineers disagree on motion | Reviewable data | JSON/typed contracts, fixtures, diagnostics |
| Platform/renderers drift | Shared behavior | Pure Dart runtime and headless snapshots |
| Games need synchronized choreography | One deterministic truth | Shared frames, identity, fixed-step input, replay hooks |

## Uses beyond demos

### Spatial onboarding and gesture education
Motion previews show direction, sequence, and consequence before a user commits to a swipe, drag, or setup action.

### Product discovery and editorial catalogs
Cards can follow a spatial rail while retaining lazy loading, stable keys, and semantics. This is the clearest use case for `MotionPathListView`.

### Maps, routes, journeys, and process timelines
Path position can communicate progress through deliveries, trips, workouts, learning, or approvals while labels and markers remain coordinated.

### Data storytelling and operational dashboards
Observation graphs can explain relationships and causality, while Canvas handles dense nodes and Widgets handle interactive detail.

### Shared list-to-detail and Hero transitions
A selected entity can move from a list or canvas into a detail route using the same runtime motion and plugin composition, rather than a hard-coded rectangle tween.

### Small game-like experiences
A single frame can drive canvas bullets, widget actors, render-object inventories, and overlay transitions. This is not a replacement for a full game engine; it is a choreography and presentation layer.

## Use it when

Motion should explain where something came from, where it goes, how things relate, what a gesture does, where the user is in a process, why a value changed, or which element has focus.

Use Flutter's normal animation APIs for a simple fade, scale, or route transition. MotionPath is justified when the system needs shared authoring, graph dependencies, input-driven progress, multiple renderers, or deterministic reuse.

## Remaining gaps

A better system still needs: entity identity and handoff semantics, capability diagnostics, cross-renderer hit testing/input routing, accessibility and reduced motion, asset/cache lifecycle, headless recording and debug tooling, serialization migrations, hot reload and recovery behavior, fixed-step game-loop input, deterministic replay, and device-specific budgets.

## Evidence and references

- [Material motion](https://m1.material.io/motion/material-motion.html): motion describes spatial relationships, functionality, and intention.
- [Material choreography](https://m1.material.io/motion/choreography.html): continuity and shared elements help users maintain focus.
- [Material navigational transitions](https://m1.material.io/patterns/navigational-transitions.html): transitions communicate hierarchy and journey.
- [Material accessibility](https://m1.material.io/usability/accessibility.html): motion cannot be the only state signal.
- [Flutter Hero animations](https://docs.flutter.dev/ui/animations/hero-animations): shared-element transitions provide route continuity.
- [Flutter CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html): repaint-driven canvas rendering is appropriate for dense visual work.
- [Flutter AnimatedList](https://api.flutter.dev/flutter/widgets/AnimatedList-class.html): standard list animation does not provide authored spatial paths.

## Validation questions

- Does the motion reduce orientation time or user error?
- Does it remain understandable with reduced motion?
- Does a path improve scanning over a normal list?
- Does the renderer system reduce custom animation code?
- Can the same motion be reused across list, canvas, detail, and Hero surfaces?
- Can a small game-like vertical slice run with one scheduler and deterministic snapshots?
