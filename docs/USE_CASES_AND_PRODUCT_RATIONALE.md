# MotionPath Flutter: use cases and product rationale

## Executive conclusion

MotionPath should make spatial relationships and state changes explicit in Flutter interfaces, without forcing teams to choose between expressive motion and native rendering behavior.

Its durable value is a portable system that describes motion as data, validates it, composes dependent tracks, drives it from time or input, and publishes one frame that Canvas, Widget, RenderObject, Overlay, or Headless targets can consume.

## Why renderer composition matters

Real products mix visual workloads. A map may draw roads on Canvas, render a selected marker as a Widget, promote that marker into a Hero Overlay, and use a RenderObject list for nearby events. A game may draw hundreds of projectiles on Canvas while the player, inventory, and dialogue remain interactive widgets. Requiring one renderer forces bad tradeoffs.

The correct model is **one runtime, many renderer instances, one primary renderer per entity**. That preserves shared truth without pretending every target has the same semantics.

## Core problems solved

1. Continuity is expensive when transitions become scattered controller code.
2. Scroll and gesture choreography needs consistent paths, easing, dependencies, and reverse behavior.
3. Rich motion fights lazy list and widget performance.
4. Motion logic gets trapped in one renderer.
5. Mixed scenes need different performance, semantics, and hit-testing tradeoffs.
6. Route and overlay transitions need the same authored behavior without a second runtime.

## Product opportunities

- Spatial onboarding and gesture education.
- Product discovery, editorial feeds, and catalogs.
- Maps, routes, journeys, and process timelines.
- Data storytelling and operational dashboards.
- Creative portfolios and immersive browsing.
- Shared list/detail/canvas/Hero transitions.
- Game scenes with Canvas crowds, interactive Widget actors, RenderObject lists, and Overlay promotion.

Motion is justified when it communicates where something went, how things relate, what a gesture will do, where the user is in a process, why a value changed, or which element has focus. It is not justified as decoration alone.

## System gaps beyond renderer formalization

Renderer composition is necessary but not sufficient. The system also needs:

- stable entity identity across spawn, recycling, route changes, and overlay promotion;
- asset lifecycle contracts for image sequences, prefetch, cache, and eviction;
- transformed hit testing and semantic projections;
- reduced-motion policy that preserves state meaning;
- frame budgeting, profiling, backpressure, and dirty-region discipline;
- fixed-step and variable-step game-loop adapters, pause/resume, visibility, and replay;
- authoring and debugging tools for graph inspection and frame preview;
- schema migration, plugin versioning, structured errors, and recovery behavior;
- cross-renderer parity fixtures and capability validation.

These are the difference between a clever animation library and a dependable system.

## Recommended validation sequence

1. Build the shared frame source and capability diagnostics.
2. Prove a mixed Canvas + Widget + RenderObject scene.
3. Add Overlay/Hero promotion and cancellation.
4. Validate the MotionPathListView and journey timeline outside the demos.
5. Build a small game vertical slice only after lifecycle, performance, and replay behavior are measurable.

## Evidence

- [Material motion](https://m1.material.io/motion/material-motion.html): motion describes spatial relationships, functionality, and intention.
- [Material choreography](https://m1.material.io/motion/choreography.html): continuity and shared elements preserve focus.
- [Material accessibility](https://m1.material.io/usability/accessibility.html): motion cannot be the only signal.
- [Flutter animation guidance](https://docs.flutter.dev/ui/animations): specialized motion systems should earn their complexity.
- [Flutter Hero animations](https://docs.flutter.dev/ui/animations/hero-animations): Hero is a shared-element transition between route states.
- [Flutter CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html): repaint-driven canvas rendering is appropriate for dense visuals.

## Validation questions

- Does mixed rendering reduce code and frame cost versus separate controllers?
- Can users explain the motion without a tooltip?
- Does reduced motion preserve comprehension?
- Can a team diagnose unsupported plugin output before shipping?
- Can the same authored frame be replayed and compared across renderers?
