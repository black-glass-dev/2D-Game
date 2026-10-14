# Operation Redline — Full Graphics Overhaul Report

**Date:** 2026-10-14 (Asia/Dhaka)

**Engine:** Godot 4.7.2, GL Compatibility renderer

**Art direction:** original golden-hour rust-red, circa-2000 desert military outpost; warm low sun, muted olive/steel fill, dust haze and clear tactical silhouettes. No neon, futuristic or sci-fi visual language is used.

## Safety and gameplay preservation

The project is a Godot 4 runtime-built `Node3D` game. Existing player movement/jump/crouch/sprint/slide/mantle, aim/fire/reload/swap, rifle/pistol ammunition, waves, Raider AI, structural collisions, score, HP/respawn, radar, touch controls, HUD editor, and both save files remain in their existing scripts and signal paths.

Visual terrain and cosmetic dressing are separate from collision geometry. The original deterministic collision floor and structural `StaticBody3D` bodies remain gameplay authority; the new terrain mesh, roof clutter, rails, windows, scenery and scatter are visual-only unless a pre-existing structural collision is retained.

## Work package record

| Package | Implemented work | Main files |
|---|---|---|
| WP1 Lighting/PBR | Filmic tonemapping, warm sun/cool fill, tuned 2-split soft shadows, sky ambient/reflection, SSAO where supported, capped lamp/muzzle lights, PBR materials with mipmapped anisotropic detail | `world_builder.gd`, `project.godot` |
| WP2 Atmosphere | Procedural sky, visible sun disc, layered dust bands, exponential atmospheric fog, GPU dust motes/embers and smooth Wave 1/2/3 fog/exposure progression | `world_builder.gd`, `main.gd` |
| WP3 Ground | Separate undulating visual terrain, detail normal map, road/pad layers, deterministic rock/drum scatter and layered strata mesas | `world_builder.gd`, `generate_assets.py`, `assets/textures/` |
| WP4 Outpost | Detailed modular facings, windows, frames, roof clutter, generator/radio pieces, container trim/stencils, lamp fixtures/spill, fences/wire, ladder/rail watchtower, crisp sign and Kenney CC0 conventional garage/window/roof/barrier/fuel/rock dressing | `world_builder.gd`, `assets/third_party/kenney_cc0/` |
| WP5 Raiders | KayKit CC0 rigged human-smuggler bases aligned to the gameplay capsule, with period tactical clothing, helmets/vests/visors, conventional carbines, health nameplates, authored two-handed/walk/shoot clips, muzzle flash, shadows and footstep dust | `enemy.gd`, `assets/third_party/kaykit_cc0/characters/` |
| WP6 Viewmodels | Detailed original rifle/pistol receivers, rails, sights, magazines, gloved forearms/hands, breathing/sway, ADS/sprint/reload/swap/recoil presentation and pooled muzzle lights, supplemented by Kenney CC0 conventional machinegun/pistol detail meshes | `rifle.gd`, `pistol.gd`, `assets/third_party/kenney_cc0/weapons/` |
| WP7 Combat VFX | Fixed pools for tracers, casings, smoke, impacts and decals; dirt/metal/concrete/flesh impact variants; ambient GPU particles and Raider step dust | `weapon_effects.gd`, weapon scripts |
| WP8 Post | Filmic tone map, restrained desert earth-tone grade, bloom, FXAA project setting, vignette-style damage treatment; effects respond to tier/settings | `world_builder.gd`, `project.godot` |
| WP9 HUD | Glass/translucent icon action controls, non-overlap defaults, animated graphical vitals, ammunition/weapon readout, tactical header, dynamic reticle/hit feedback, restyled radar/FOV cone/pulsing contacts | `main.gd`, `tactical_radar.gd` |
| WP10 Load | Original operation loading splash shown while the runtime scene builds | `main.gd` |
| WP11 Performance | AUTO/LOW/MEDIUM/HIGH/ULTRA setting, mobile auto-detect, dynamic 3D render scale, 2-second load shed, 7-second recovery, tier-based lights/shadows/SSAO/glow/particles | `game_settings.gd`, `performance_governor.gd`, `world_builder.gd`, `main.gd` |

## CC0 period-art replacement — conventional, auditable external assets

The later art pass replaces the futuristic read rather than merely changing colour values. Deliberately small downloaded Kenney and KayKit CC0 subsets are vendored with exact source paths, source commits and licence terms in [`assets/third_party/kenney_cc0/README.md`](assets/third_party/kenney_cc0/README.md) and [`assets/third_party/kaykit_cc0/README.md`](assets/third_party/kaykit_cc0/README.md), and credited in [`CREDITS.md`](CREDITS.md).

- **Weapons:** conventional pistol/machinegun detail meshes are layered into the existing service sidearm, player carbine and Raider carbine rigs; the existing ADS, recoil, muzzle, ammunition and hit logic stays authoritative.
- **Characters:** one shared external KayKit CC0 human rig provides every Raider body. The vendored 2.4 MB derivative retains only its authored two-handed aim/shoot and walk clips; source knife, crossbow, throwable, cape and exaggerated-head meshes are removed before import. The body is scale-aligned to the gameplay capsule and given an original compact helmeted head, olive/charcoal clothing, field vest, scarf, open visor and non-glowing carbine. Material variants supply encounter variety without loading a second animation library. No alien, armoured-soldier franchise look, neon or energy weapon is used.
- **Buildings and props:** garage/window bays, corrugated roofs, damaged concrete barriers, fuel drums, sheet-metal repairs and sand rocks dress the retained original collision-safe outpost. These are ordinary early-2000s border/military logistics elements, not space/cyberpunk pieces.
- **Performance and safety:** imported pieces are grouped into the existing LOW/MEDIUM/HIGH/ULTRA dressing budgets. Collision, pathing, waves, score, HUD saves and touch systems remain the existing authored implementation.

Only assets selected for the real-world period are shipped. The source subset expressly excludes Kenney space, blaster, alien, laser and futuristic environment pieces, and the project contains no commercial-game asset, character, map, brand or logo.

## Post-package visual polish — CI renderer verified

A second direct presentation pass was made after reviewing the captured frames rather than treating the first asset pass as final. It preserves every gameplay node and collision body while improving the weakest visual reads:

- **Terrain:** finite-difference normals shade the cosmetic dunes correctly; three-frequency dune/ripple height, tyre-track segments, windblown scrap and dry-brush clusters add depth while the original flat collision floor remains authoritative.
- **Architecture:** window frames are rails/mullions instead of opaque plates that hide reflective glass; the outpost name has a high-contrast metal plaque and camera-readable sign treatment.
- **Materials:** terrain/building tint values preserve PBR micro-detail and cool/warm separation under the low sun.
- **HUD:** new-player defaults use a spaced circular right-thumb cluster, eliminating the old SWAP/CROUCH conflict; all previous saved layouts still load untouched. Action press scale/haptic feedback and a true movement/ADS-responsive four-segment reticle are active.
- **Characters/VFX:** Raiders now use a front-facing tactical capture pose, compact helmet/visor/mask stack, plate carrier/pouches/arm bands/knee pads, aimed carbine silhouette and layered rifle/pistol muzzle-flash cores. These changes are presentation-only; their capsule/headshot collision remains unchanged.
- **Evidence:** the real capture harness places its showcase Raider in clear gameplay lanes at explicit 15 m and 5 m distances, turns its encounter-facing front toward the capture camera, and captures short-lived firing/low-health states on the immediate rendered frame.

The source/static/project/native checks, Android export, headless startup and refreshed OpenGL before/after capture all passed in [GitHub Actions run 38355410579](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38355410579). It generated candidate #48 and refreshed all 12 after frames.

## Priority ADS repair — black-scope fallback eliminated

The black optic failure was traced to the carbine viewmodel's former opaque sight block, not a required second-camera rendering feature. The mobile path now keeps the primary `PlayerCamera` as the only world renderer:

- Carbine ADS uses a `75° → 40°` and back FOV tween (`TRANS_CUBIC`, `EASE_OUT`, `0.16 s`). Sidearm uses `55°` through the same controller.
- ADS multiplies the saved look sensitivity by `0.45`; it does not overwrite the player's LOOK setting.
- `assets/shaders/ads_glass.gdshader` is a mouse-ignoring transparent CanvasLayer treatment: a low-alpha glass tint, soft peripheral vignette and non-intercepting plus/ghost-ring reticle. Its center stays transparent and cannot display a second black render target.
- The old filled holographic box is replaced by an open reflex housing made of two rails, base/brow and a transparent emissive cyan lens. The carbine ADS pose seats this physical frame below the reticle, leaving the actual main-camera world visible at screen centre.
- Hip reticle is hidden during ADS and restored on release. Reload and weapon swap cancel ADS before their existing actions. Raider nameplates hide only while the player is aiming so labels never cross the reticle.
- There is intentionally no mobile `SubViewport`, `ViewportTexture`, opaque scope `ColorRect`, or lens watchdog needed on this route. This avoids the former second-render black frame and its fill-rate cost at MEDIUM, HIGH and ULTRA.

The real capture harness performs the same FOV/ADS call used by gameplay and waits for its 0.16-second transition before writing `screenshots/after/09_ads.png`. GitHub Actions run [38379198434](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38379198434) passed source, Android export, headless startup and all 12 genuine renderer captures for this repair.

## Quality tiers

| Tier | 3D scale | Presentation budget | Governor behaviour |
|---|---:|---|---|
| LOW | 68% | no directional shadows, SSAO, lamps, dust or embers; 24 cosmetic scatter meshes | **locked** — no adaptive override |
| MEDIUM | 75% | 28 m directional shadow, three local lamps, 52 scatter meshes and 42% wave particles; no bloom/SSAO | **locked** — no adaptive override |
| HIGH | 90% | 48 m soft directional shadow, five local lamps, 86 scatter meshes, bloom, SSAO and 78% wave particles | **locked** — no adaptive override |
| ULTRA | 100% | 70 m shadow range, six local lamps, all 112 scatter meshes, strongest bloom/SSAO and full particles | **locked** — no adaptive override |
| AUTO | detected | selects LOW/MEDIUM/HIGH from processor capability | only this mode may lower 3D scale by 10%, turn off expensive lights/shadows and reduce particles after two seconds below target; restores after seven stable seconds |

The governor only changes rendering. It never reduces game simulation, input, enemy count, waves or HUD rate.

## Mobile fire modes

The original tap behaviour remains the default **SINGLE** mode. A new persisted `SINGLE` / `AUTO` selector is placed above-left of the existing FIRE circle, is movable/resizable in the HUD editor, and never changes the FIRE hit area. In SINGLE mode `button_down` calls the existing weapon shot once. In AUTO mode, holding FIRE repeatedly calls that same shot path and each rifle/pistol's existing cooldown remains the sole rate-of-fire authority. Damage, magazines, reserve ammunition, recoil, aim assist and wave/AI logic are shared with the original single shot code rather than duplicated.

## Verification and screenshot honesty

Local static validation after each committed package passed:

- GDScript analysis: 13 scripts, 0 errors, 0 warnings
- project/resource validation
- native three-wave core tests
- `git diff --check`

A local Godot 4.7.2 binary download was attempted twice for runtime rendering and screenshot capture, but this sandbox's release CDN connection failed (`curl: (35) SSL_ERROR_SYSCALL`; `wget` exit 4). The workflow therefore runs a real Godot/OpenGL llvmpipe capture harness under Xvfb instead. It loads the actual gameplay scene and saves viewport pixels; it does not mock or compose images. The genuine first comparison capture is committed under `screenshots/before/` and `screenshots/after/` (11 named Section 8 states). The capture harness has since been expanded to refresh **12** states, including explicit 15 m and 5 m Raider frames, on the next visual workflow run.

The generated comparison captured the pre-overhaul baseline at its former 800×450 render design and the overhaul at 1280×720. The HUD/full-screen canvas, sun/fog palette, terrain texture detail, outpost dressing, viewmodel and revised controls are visibly present in the after set. Rendering was verified on CI's Mesa llvmpipe software OpenGL implementation, not representative phone hardware; it is valid visual evidence but not a mobile FPS measurement.

The mandatory Android emulator smoke runner has historically timed out booting before install in this repository. That infrastructure failure must not be read as a gameplay pass or a physical device result. Export/signature/headless results and a real-device playthrough are still required before describing any candidate as physical-device verified.

## Known renderer fallbacks

- The project intentionally remains on the mobile-compatible GL renderer. On renderers/devices without SSAO or costly volumetrics, the fallback is PBR texture detail, ambient sky fill, contact-producing tuned shadows, fog, horizon cards, emissive spill, and GPU dust.
- Godot Compatibility does not need a second camera viewport for the viewmodel: weapon/hands use a no-depth-test material fallback and close camera placement to prevent wall clipping while avoiding an extra mobile render pass.
- Heat haze and motion blur are intentionally excluded from LOW/MEDIUM; fog, grade, bloom and dynamic resolution provide the cheaper equivalent.

## Required final visual QA

The CI harness captures genuine before/after shots of the defined spawn, lane, crate, sign, horizon, Raider 15 m/5 m, rifle idle/ADS/firing, low-HP, reload and crouch viewpoints. Inspect the 1280×720 after frames and repeat this check on a physical Android device before signing a final physical-device APK.
