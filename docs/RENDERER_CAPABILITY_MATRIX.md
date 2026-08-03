# Renderer capability matrix

This is the initial contract map. `Yes` means the renderer should support the output directly. `Adapter` means it can support it through a target-specific layer. `No` means the renderer should reject or explicitly ignore it.

| Capability | Canvas | Widget | RenderObject | Overlay | Headless |
|---|---:|---:|---:|---:|---:|
| x/y/z transform | Yes | Yes | Yes | Yes | Yes |
| rotation / scale | Yes | Yes | Yes | Yes | Yes |
| opacity | Yes | Yes | Yes | Yes | Yes |
| blur / filter | Yes | Adapter | Yes | Adapter | Sample |
| image sequence | Yes | Yes | Yes | Yes | Sample |
| CSS variables | No | Adapter | Adapter | Adapter | Yes |
| custom geometry | Yes | No | Adapter | Adapter | Yes |
| spawned entities | Yes | Yes | Yes | Adapter | Yes |
| semantic tree | No | Yes | Yes | Adapter | No |
| hit testing | Adapter | Yes | Yes | Adapter | No |
| z/depth ordering | Yes | Adapter | Yes | Yes | Yes |
| route/hero flight | No | No | No | Yes | Sample |

## Rules

- Capability checks happen before mounting when the required output set is known.
- Optional fields may be ignored only with explicit metadata.
- A renderer must not silently reinterpret a plugin field with different semantics.
- One entity has one primary renderer at a time, but a scene can contain many renderer types.
- A shared runtime can feed multiple renderers and entities.
- This matrix is versioned with the public patch contract.

## Current status

The repository has working pieces for Canvas-style painters, widget patch/spawn views, transforms, filters, depth, image caching, and hit testing. Formal capability metadata, a shared frame source, RenderObjectRenderer, OverlayRenderer, and HeadlessRenderer remain planned work.
