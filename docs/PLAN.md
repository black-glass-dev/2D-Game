# Operation Redline — development plan

## Product definition

**Genre:** Offline, single-player, first-person enemy-wave survival game for Android.

**Setting:** An original present-day military outpost on the edge of a dry border town. The player has interrupted a smuggling operation and must hold the outpost while raiders try to recover their cargo. The game does not use people, places, stories, art, or branding from Call of Duty or any other game.

**Visual direction:** Retro 128×128-texture / pixel-art-inspired 3D. The target is sharp, deliberate pixels with a warm desert palette—not a flat 2D map. Depth comes from terrain terraces, watchtowers, buildings, interior cover, distant mountains, fog, shadow, and contrasting practical lights.

**Working title:** `Operation Redline`.

## First playable release (vertical slice)

| Area | Included in the first APK |
| --- | --- |
| Platform | Android, landscape orientation, offline |
| Controls | Two touch zones for move/look, Fire, Reload, Aim; keyboard/mouse support for development testing |
| Arena | One layered desert outpost with command building, watchtower, depot, barriers, alleys, perimeter and distant mountains |
| Combat | Hitscan rifle, magazine/ammo, reload timing, recoil, muzzle flash, hit confirmation, health and respawn |
| Enemies | Procedural human-scale raider silhouettes; pursuit, line-of-sight firing, damage, death and wave spawning |
| Progression | Three escalating waves, intermission, clear/fail screens, score and accuracy |
| Visuals | Pixel scale, authored 128×128 textures, directional shadows, baked-looking warm lighting, fog, emissive lamps and UI vignette |
| Performance | Low-poly modular geometry, pooled enemies, mobile renderer, conservative shadow/light counts |

## Technical architecture

```text
project.godot
scenes/Main.tscn            Startup scene
scripts/main.gd             Match state, input and HUD
scripts/world_builder.gd    Procedural modular outpost / lighting
scripts/player.gd           CharacterBody3D movement, camera and mobile input
scripts/rifle.gd            Weapon presentation and firing bridge
scripts/enemy.gd            Raider navigation / combat / damage
scripts/wave_director.gd    Integration layer for the native director
native/                     C++ survival pacing and combat-statistics core
assets/                     Original generated textures, icons and sound effects
```

Gameplay logic that benefits from deterministic state—wave pacing and state transitions—is implemented in a portable C++ core with unit tests. It is structured for a Godot GDExtension/Android NDK build; until that binary is compiled, the Godot scene adapter mirrors the same contract. Scene construction, platform input and animation intentionally stay in Godot scripts because they require engine callbacks and make Android iteration dependable.

## Delivery and verification gates

1. **Foundation:** Reproducible project structure, versioned scope, original asset manifest and input map.
2. **Playable desktop validation:** Godot imports the project, all scripts parse, startup scene loads, and automated core C++ tests pass.
3. **Android build validation:** Android SDK, JDK, Godot export templates, debug signing and Gradle export are configured. A debug APK is generated from the exact source in this repository.
4. **APK validation:** Inspect APK contents/signature, install/launch on an Android emulator or device when available, record results in `docs/TEST_REPORT.md`.
5. **Handoff:** Only a build that passes the recorded checks is labelled as tested. The APK is a build artifact and is deliberately ignored by Git; source, configuration and test report remain in the repository.

## Honest constraints

- This is a new original game, not a Call of Duty clone.
- “128bit” is treated as the confirmed 128×128 retro pixel-texture art direction; it is not a hardware or Android colour-depth requirement.
- A full commercial AAA shooter, online multiplayer, licensed assets and a long campaign are outside the first release. The first release prioritizes one polished, replayable survival outpost.
- Android tools were absent when planning started. No APK will be described as tested until the export toolchain and the recorded test gates actually pass.

## Phased implementation

1. Build project shell, world palette and controls.
2. Implement movement, weapon, enemy and survival loop.
3. Add native C++ director and its unit tests.
4. Author visual polish, original pixel textures, lights and HUD.
5. Configure Android export, make debug APK, test and document the outcome.
