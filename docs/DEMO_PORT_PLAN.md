# JS demo port plan

Updated 2026-08-03 against the JS demo route map in `apps/demo/src/App.jsx`.

## Scope

Port every actual demo route from the JS source into Flutter. Exclude
`/spike-refresh` and `/spike-stagger`: those are diagnostic spike pages, not
product demos.

Already ported:

- Carousel: complete, PRs #93, #94, and #114 through #122.
- Spiral/Zuma: existing Flutter example, still needs a renderer-consumption audit because the current host retains some local patch plumbing.
- Helix/depth: complete, PRs #124 through #126.
- Walker: scene graph and real FK host merged, PRs #127 through #129.
- Burst: scene contract and spawn host merged, PRs #130 and #132.
- Motorcycle: scene contract and vector-art host merged, PRs #131 and #134.

## Remaining demo matrix

| Order | JS route | Source contract | Flutter target | Status |
|---:|---|---|---|---|
| 1 | `/walker` | FK chain, scroll scrub, 14 bone tracks, world-space patches, tone layering | `walker_demo.dart` plus shared Walker scene builder | Complete, PRs #127 through #129 |
| 2 | `/burst` | Scroll-driven radial burst, staggered transforms, opacity, scale, and color | `burst_demo.dart` plus sampled burst scene | Complete, PRs #130 and #132 |
| 3 | `/moto` | Scroll-driven motorcycle assembly, nested transforms, image/asset composition | `motorcycle_demo.dart` plus asset contract | Complete, PRs #131 and #134. Imagery is vector art by decision, recorded in `docs/COMPATIBILITY.md` |
| 4 | `/pasarmalam` | Multi-track festival scene, scroll orchestration, authored plugin payloads | `pasar_malam_demo.dart` plus scene contract | Planned |
| 5 | `/pasarmalam-observer` | Observer/input-output graph variant of Pasar Malam | `pasar_malam_observer_demo.dart` plus graph fixtures | Planned |
| 6 | `/tower-defense` | Dynamic units, target/attack state, spawned children, interaction | `tower_defense_demo.dart` plus lifecycle contract | Planned |
| 7 | `/hooks-demo` | Hook/runtime integration showcase and baseline consumer | `hooks_demo.dart` plus minimal project contract | Planned |

## Porting rules

1. Inventory the JS page, motion builder, assets, and tests before writing Dart.
2. Extract authored scene data into a shared `*_scene.dart` builder. Do not copy path, progress, easing, or visual interpolation literals into the widget.
3. Reuse generic patch consumers, Walker/FK rendering, scroll bindings, spawn hosts, image cache, and plugin adapters. No demo-specific engine math.
4. Add sampled scene tests before widget tests. Assert representative patch keys, numeric tolerance, lifecycle boundaries, and disappearance behavior.
5. Add a real Flutter host test for mount, interaction, reverse/re-entry where applicable, and teardown. Keep host tests scoped to the host, not framework wrapper widgets.
6. Record intentional Flutter/JS differences in `docs/COMPATIBILITY.md` with owner and regression evidence.
7. Merge one demo PR only after all four CI jobs are green. Docs-only updates go directly to `main`.

## Parallelization

Safe parallel workstreams:

- Pasar Malam and Tower Defense scene inventories can proceed independently.
- Observer work follows the Pasar Malam base scene contract but its fixture inventory can start in parallel.

Do not parallelize edits to shared public renderer files without a dedicated contract PR first. Keep each demo in its own branch and PR.

## Consistency audit checklist

For each port, compare the JS route against Flutter before marking complete:

- Route exists and launches from the Flutter example.
- Every JS motion/track has a Dart scene builder or an explicit unsupported asset decision.
- Every authored property reaches a composed patch or is documented as host chrome.
- Scroll, trigger, repeat, stagger, observer, and lifecycle semantics match.
- Asset paths, image-frame payloads, CSS-variable payloads, and plugin outputs have a Flutter host consumer or an accepted difference.
- Widget tests cover the host behavior without counting framework-owned widgets.
- Public APIs stay in package exports; demo helpers stay in `example/lib`.
- Docs, phase status, changelog, and compatibility notes agree.

## Known audit gap

`example/lib/main.dart` still boots a single hard-coded page, so Carousel,
Helix, Burst, and Motorcycle are reachable from tests but not from the running
example app. The first checklist line stays open for every ported demo until a
demo launcher lands. Track that as its own PR rather than folding it into a
port.

## Current next tasks

1. Add a demo launcher to `example/lib/main.dart` so every ported route is reachable from the running app.
2. Inventory and port Pasar Malam, then its observer variant.
3. Port Tower Defense, then Hooks Demo.
4. Audit the Spiral/Zuma host for leftover local patch plumbing.
