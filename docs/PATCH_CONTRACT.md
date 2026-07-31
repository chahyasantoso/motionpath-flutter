# Renderer-neutral patch contract

The core publishes immutable JSON-shaped snapshots. Flutter and other hosts consume these snapshots without reaching back into authored keyframes.

## Key categories

- **Public output:** authored renderer values such as `x`, `y`, `rotation`, `scale`, `opacity`, and `color`.
- **Renderer metadata:** host-facing depth and visibility hints such as `z`, `perspective`, and `visible`.
- **Plugin payload:** outputs declared by a registered plugin, including `filter`, `image`, `cssVariables`, `instances`, and path-derived position values.
- **Internal:** composition-only values such as `progress`, `boneLength`, `boneRotation`, and `parentWorld`. These never cross the public patch boundary.

## Units and semantics

- `x`, `y`, and `z` are logical renderer units.
- `rotation` and FK rotations are authored degrees. Flutter converts to radians at the renderer boundary.
- `scale`, `scaleX`, and `scaleY` are unitless factors.
- `opacity` is normalized to `[0, 1]` by the host renderer.
- `color` is packed ARGB in the Dart core.
- `filter` is a typed numeric filter payload; hosts validate values such as blur sigma.
- `image` is a resolved frame identifier. Loading and cache ownership stay outside core.
- `instances` is a bounded list of immutable child payloads with stable host-defined identity.
- `cssVariables` is typed host data, not a promise that CSS custom properties exist in Flutter.

Every public patch is recursively immutable. Consumers must copy values before adapting them to mutable framework objects.
