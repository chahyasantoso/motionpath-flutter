# MotionPath Flutter examples

## Pinned viewport and dynamic spawn

```sh
flutter pub get
flutter run
```

This is a diagnostic scene for viewport pin state and manual dynamic spawning.
The Spawn dot button now keeps children mounted, so the visible count grows and
can be inspected directly.

## Zuma / Spiral

```sh
flutter run -t lib/spiral_main.dart
```

This is the Flutter port's closest equivalent to the JavaScript MotionPath
Spiral/Zuma demo. Balls auto-spawn every 700ms from the shared ticker, travel
along a rendered spiral guide, and drain after eight seconds. Tap a ball to pop
it; the spawn controller reflows the remaining chain through its layout policy.
The demo is intentionally renderer-neutral in its engine state and owns only
painting and hit testing in the host widget.
