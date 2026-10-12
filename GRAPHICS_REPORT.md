# Operation Redline — Full Graphics Overhaul Report

**Date:** 2026-10-12 (Asia/Dhaka)

**Engine:** Godot 4.7.2, GL Compatibility renderer

**Art direction:** original golden-hour rust-red military outpost; warm low sun, cool teal fill, dust haze and clear tactical silhouettes.

## Safety and gameplay preservation

The project is a Godot 4 runtime-built `Node3D` game. Existing player movement/jump/crouch/sprint/slide/mantle, aim/fire/reload/swap, rifle/pistol ammunition, waves, Raider AI, structural collisions, score, HP/respawn, radar, touch controls, HUD editor, and both save files remain in their existing scripts and signal paths.

Visual terrain and cosmetic dressing are separate from collision geometry. The original deterministic collision floor and structural `StaticBody3D` bodies remain gameplay authority; the new terrain mesh, roof clutter, rails, windows, scenery and scatter are visual-only unless a pre-existing structural collision is retained.

## Work package record

| Package | Implemented work | Main files |
|---|---|---|
| WP1 Lighting/PBR | Filmic tonemapping, warm sun/cool fill, tuned 2-split soft shadows, sky ambient/reflection, SSAO where supported, capped lamp/muzzle lights, PBR materials with mipmapped anisotropic detail | `world_builder.gd`, `project.godot` |
| WP2 Atmosphere | Procedural sky, visible sun disc, layered dust bands, exponential atmospheric fog, GPU dust motes/embers and smooth Wave 1/2/3 fog/exposure progression | `world_builder.gd`, `main.gd` |
| WP3 Ground | Separate undulating visual terrain, detail normal map, road/pad layers, deterministic rock/drum scatter and layered strata mesas | `world_builder.gd`, `generate_assets.py`, `assets/textures/` |
| WP4 Outpost | Detailed modular facings, windows, frames, roof clutter, generator/radio pieces, container trim/stencils, lamp fixtures/spill, fences/wire, ladder/rail watchtower and crisp sign | `world_builder.gd` |
| WP5 Raiders | Three articulated tactical variants, helmets/vests/visors, weapon, health nameplate, procedural walk/aim/fire/reload/hit/death animation, muzzle flash, shadows and footstep dust | `enemy.gd` |
| WP6 Viewmodels | Detailed original rifle/pistol receivers, rails, sights, magazines, gloved forearms/hands, breathing/sway, ADS/sprint/reload/swap/recoil presentation and pooled muzzle lights | `rifle.gd`, `pistol.gd` |
| WP7 Combat VFX | Fixed pools for tracers, casings, smoke, impacts and decals; dirt/metal/concrete/flesh impact variants; ambient GPU particles and Raider step dust | `weapon_effects.gd`, weapon scripts |
| WP8 Post | Filmic tone map, teal/orange grade, bloom, FXAA project setting, vignette-style damage treatment; effects respond to tier/settings | `world_builder.gd`, `project.godot` |
| WP9 HUD | Glass/translucent icon action controls, non-overlap defaults, animated graphical vitals, ammunition/weapon readout, tactical header, dynamic reticle/hit feedback, restyled radar/FOV cone/pulsing contacts | `main.gd`, `tactical_radar.gd` |
| WP10 Load | Original operation loading splash shown while the runtime scene builds | `main.gd` |
| WP11 Performance | AUTO/LOW/MEDIUM/HIGH/ULTRA setting, mobile auto-detect, dynamic 3D render scale, 2-second load shed, 7-second recovery, tier-based lights/shadows/SSAO/glow/particles | `game_settings.gd`, `performance_governor.gd`, `world_builder.gd`, `main.gd` |

## Quality tiers

| Tier | 3D scale | Presentation budget | Intended target |
|---|---:|---|---|
| LOW | 68% | no directional shadows/SSAO; bloom/effects constrained | lower-end Android, stable play over image detail |
| MEDIUM | 80% | tuned shadows, FXAA, modest fog/particles | 30–60 FPS mobile |
| HIGH | 92% | filmic glow, shadows, SSAO where renderer supports it, full dust | Snapdragon 7-class / 6 GB target at 60 FPS |
| ULTRA | 100% | largest shadow range and full effects budget | high-end Android/Desktop |
| AUTO | detected | selects LOW/MEDIUM/HIGH from processor capability, then governor can reduce presentation | first launch |

The governor only changes rendering. It never reduces game simulation, input, enemy count, waves or HUD rate.

## Verification and screenshot honesty

Local static validation after each committed package passed:

- GDScript analysis: 13 scripts, 0 errors, 0 warnings
- project/resource validation
- native three-wave core tests
- `git diff --check`

A local Godot 4.7.2 binary download was attempted twice for runtime rendering and screenshot capture, but this sandbox's release CDN connection failed (`curl: (35) SSL_ERROR_SYSCALL`; `wget` exit 4). Therefore **no before/after images are claimed or fabricated**. `screenshots/before/` and `screenshots/after/` are intentionally held for real capture only. The committed GitHub workflow is the next valid Godot import/export/headless scene gate.

The mandatory Android emulator smoke runner has historically timed out booting before install in this repository. That infrastructure failure must not be read as a gameplay pass or a physical device result. Export/signature/headless results and a real-device screenshot pass are still required before describing any candidate as physical-device verified.

## Known renderer fallbacks

- The project intentionally remains on the mobile-compatible GL renderer. On renderers/devices without SSAO or costly volumetrics, the fallback is PBR texture detail, ambient sky fill, contact-producing tuned shadows, fog, horizon cards, emissive spill, and GPU dust.
- Godot Compatibility does not need a second camera viewport for the viewmodel: weapon/hands use a no-depth-test material fallback and close camera placement to prevent wall clipping while avoiding an extra mobile render pass.
- Heat haze and motion blur are intentionally excluded from LOW/MEDIUM; fog, grade, bloom and dynamic resolution provide the cheaper equivalent.

## Required final visual QA

Capture genuine before/after shots of the defined spawn, lane, crate, sign, horizon, Raider 15 m/5 m, rifle idle/ADS/firing, low-HP, reload and crouch viewpoints once a renderer is available. Inspect those actual frames at native landscape resolution before signing a final APK.
