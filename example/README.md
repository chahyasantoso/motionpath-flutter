# MotionPath Flutter example

Run from this directory:

```sh
flutter pub get
flutter run
```

The example intentionally exercises both adapter boundaries in one scene:

- scroll sampling drives `MotionPathViewportBinding`, which reports visibility,
  progress, paint offset, and pin state without creating a clock or mutating
  layout;
- the Spawn button adds dynamic children to `MotionPathSpawnController`, and
  `MotionPathSpawnTickerBinding` advances them from the same ticker as the time
  motion.

The host widget owns the actual painting and disposes every route-owned binding.
