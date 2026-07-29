# Dependency decisions

## Decision

Keep the MotionPath engine core custom and pure Dart. Use Flutter's built-in `Ticker`, `CustomPainter`, `Matrix4`, and scroll APIs in the adapter. Do not make `flutter_animate` a core dependency.

## Why not flutter_animate?

`flutter_animate` is excellent for declarative widget effects and quick UI motion, but MotionPath needs a data-first runtime with immutable observation graphs, parent-before-child composition, renderer-neutral patches, custom plugins, forward kinematics, headless execution, and deterministic fixture compatibility with the JavaScript engine. Those are outside its abstraction boundary. Adding it would create two animation models and make the core depend on Flutter.

It may be used later in an example app for presentation-only effects, never inside `motionpath_core` and never as the MotionPath clock.

## Allowed dependency rule

Prefer platform primitives for engine semantics. Add a package only when it removes substantial complexity without owning scheduling, graph composition, or schema behavior. Every dependency needs a documented reason, a license check, and a headless-test story.
