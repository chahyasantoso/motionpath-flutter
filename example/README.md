# MotionPath Flutter examples

From this directory, always refresh the package graph before analyzing or running an example:

```sh
flutter pub get
flutter analyze
```

## Pinned viewport and dynamic spawn

```sh
flutter run
```

This is a diagnostic scene for viewport pin state and manual dynamic spawning.
The Spawn dot button keeps children mounted, so the visible count grows and can
be inspected directly.

## Zuma / Spiral

```sh
flutter run -t lib/spiral_main.dart
```

This is the Flutter port's closest equivalent to the JavaScript MotionPath
Spiral/Zuma demo. Balls auto-spawn every 700ms from the shared ticker, travel
along a rendered spiral guide, and drain after eight seconds. Tap a ball to pop
it; the spawn controller reflows the remaining chain through its layout policy.
