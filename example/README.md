# MotionPath Flutter examples

## Pinned viewport and dynamic spawn

```sh
flutter pub get
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
Spiral/Zuma demo. The ball track is authored as v4 JSON, validated, and resolved
into each spawned runtime child. Balls auto-spawn every 1.25 seconds from the
shared ticker, travel for 12 seconds along a three-and-a-half-turn spiral, and
use 42px diameter circles. When the chain drains to zero, the next ticker frame
respawns a ball at the outer start. Tap a ball to pop it; the spawn controller
reflows the remaining chain through its layout policy.

The host owns painting and hit testing. The engine still owns schema validation,
playheads, lifecycle, and the one shared clock.

CI note: the example is analyzed and tested as a first-class Flutter package.
