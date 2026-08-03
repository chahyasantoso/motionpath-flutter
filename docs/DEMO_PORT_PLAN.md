# JS demo port plan

Updated 2026-08-03 against the JS demo route map in `apps/demo/src/App.jsx`.

## Scope

Port every actual demo route from the JS source into Flutter. Exclude
`/spike-refresh` and `/spike-stagger`: those are diagnostic spike pages, not
product demos.

Already ported:

- Carousel: complete, PRs #93, #94, and #114 through #122.
- Spiral/Zuma: complete after the generic spawn-renderer audit, PR #144.
- Helix/depth: complete, PRs #124 through #126.
- Walker: scene graph and real FK host merged, PRs #127 through #129.
- Burst: scene contract and spawn host merged, PRs #130 and #132.
- Motorcycle: scene contract and vector-art host merged, PRs #131 and #134.
- Pasar Malam: scene contract and scroll host merged, PRs #136 and #137.
- Pasar Malam Observer: observer-driven host merged, PR #138.
- Tower Defense: scene contract and interactive host merged, PRs #139 and #141.
- Hooks Demo: scene contract and host merged, PRs #140 and #142.

## Remaining demo matrix

| Order | JS route | Source contract | Flutter target | Status |
|---:|---|---|---|---|
| 1 | `/walker` | FK chain, scroll scrub, 14 bone tracks, world-space patches, tone layering | `walker_demo.dart` plus shared Walker scene builder | Complete, PRs #127 through #129 |
| 2 | `/burst` | Scroll-driven radial burst, staggered transforms, opacity, scale, and color | `burst_demo.dart` plus sampled burst scene | Complete, PRs #130 and #132 |
| 3 | `/moto` | Scroll-driven motorcycle assembly, nested transforms, image/asset composition | `motorcycle_demo.dart` plus asset contract | Complete, PRs #131 and #134 |
| 4 | `/pasarmalam` | Multi-track festival scene, scroll orchestration, authored plugin payloads | `pasar_malam_demo.dart` plus scene contract | Complete, PRs #136 and #137 |
| 5 | `/pasarmalam-observer` | Observer/input-output graph variant of Pasar Malam | `pasar_malam_observer_demo.dart` plus graph fixtures | Complete, PR #138 |
| 6 | `/tower-defense` | Dynamic units, target/attack state, spawned children, interaction | `tower_defense_demo.dart` plus lifecycle contract | Complete, PRs #139 and #141 |
| 7 | `/hooks-demo` | Hook/runtime integration showcase and baseline consumer | `hooks_demo.dart` plus minimal project contract | Complete, PRs #140 and #142 |

## Porting rules

1. Inventory the JS page, motion builder, assets, and tests before writing Dart.
2. Extract authored scene data into a shared `*_scene.dart` builder. Do not copy path, progress, easing, or visual interpolation literals into the widget.
3. Reuse generic patch consumers, Walker/FK rendering, scroll bindings, spawn hosts, image cache, and plugin adapters. No demo-specific engine math.
4. Add sampled scene tests before widget tests. Assert representative patch keys, numeric tolerance, lifecycle boundaries, and disappearance behavior.
5. Add a real Flutter host test for mount, interaction, reverse/re-entry where applicable, and teardown. Keep host tests scoped to the host, not framework wrapper widgets.
6. Record intentional Flutter/JS differences in `docs/COMPATIBILITY.md` with owner and regression evidence.
7. Merge one demo PR only after all four CI jobs are green. Docs-only updates go directly to `main`.

## Consistency audit checklist

- Route exists and launches from the Flutter example: complete for all nine ported demos via the launcher.
- Every JS motion/track has a Dart scene builder or an explicit unsupported asset decision: complete for the nine routes.
- Every authored property reaches a composed patch or is documented as host chrome: complete for the current demo scope.
- Scroll, trigger, repeat, stagger, observer, and lifecycle semantics match: covered by scene and host tests; remaining differences are documented.
- Asset paths, image-frame payloads, CSS-variable payloads, and plugin outputs have a Flutter host consumer or an accepted difference: accepted asset-free sequence presentation is documented for Pasar Malam.
- Widget tests cover host behavior without counting framework-owned widgets: complete for current demo hosts.
- Public APIs stay in package exports; demo helpers stay in `example/lib`: complete for current demo scope.
- Docs, phase status, changelog, and compatibility notes agree: refreshed on main.

## Current next tasks

1. Run the release-hardening checklist from clean package directories.
2. Review public exports and publish metadata, then run both package dry-runs.
3. Capture controlled benchmark JSON and complete the security/release evidence.
"},{