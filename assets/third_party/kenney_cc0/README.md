# Kenney CC0 outpost asset subset

**Retrieved:** 2026-10-13  
**Source mirror:** [`shorepine/kenney`](https://github.com/shorepine/kenney) at commit [`3694c6879e487c108f55677be7dd2ca75b07cc3b`](https://github.com/shorepine/kenney/commit/3694c6879e487c108f55677be7dd2ca75b07cc3b)  
**Original creator:** Kenney / [kenney.nl](https://kenney.nl)  
**License:** [Creative Commons Zero 1.0 Universal (CC0)](https://creativecommons.org/publicdomain/zero/1.0/)

The source mirror describes its collection as Kenney art released under CC0 and documents that models keep their own relative `Textures/` directory. The original paths and compatible texture dependencies are retained below so this deliberately small vendored subset remains auditable and reproducible.

## Imported files and original paths

| Local files | Original source path | In-game role |
| --- | --- | --- |
| `weapons/pistol.glb` | `3d/weapon/pistol.glb` | Player sidearm detail mesh |
| `weapons/machinegun.glb` | `3d/weapon/machinegun.glb` | Player rifle and raider carbine detail mesh |
| `characters/{blocky_smuggler_a,blocky_smuggler_b}.glb`, `characters/Textures/{texture-a,texture-b}.png` | `3d/blocky-characters/character-{a,b}.glb`, `3d/blocky-characters/Textures/texture-{a,b}.png` | Animated hostile-smuggler base character variants |
| `outpost/{wall_window,wall_garage,roof_metal,barrier_damaged}.glb` and their `outpost/Textures/*` dependencies | `3d/retro-urban/` equivalents and `3d/retro-urban/Textures/*` | Conventional outpost architecture and fortified barriers |
| `props/{barrel,metal_panel,rock_sand_a,rock_sand_b}.glb`, `props/Textures/colormap.png` | `3d/survival/` equivalents and `3d/survival/Textures/colormap.png` | Fuel drums, field repairs and desert rocks |

The relative texture folders are required by the GLB image references and are intentionally kept next to the relevant models. No commercial-game art, characters, maps, brands, or logos are included.

## Scope selection

Only conventional 2000-era-adjacent elements were selected: pistols/carbines, two human smuggler variants, industrial walls/garage bays, sheet-metal roofs, concrete barriers, fuel drums, metal repairs and desert rocks. No Kenney space, blaster, alien, laser, or futuristic environment assets are used by Operation Redline.

Attribution is not required by CC0, but Operation Redline credits Kenney voluntarily. See the repository-level `CREDITS.md` for the concise product credit.
