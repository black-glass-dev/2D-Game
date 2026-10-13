# Operation Redline — Graphics Overhaul Progress

_Last updated: 2026-10-13 (Asia/Dhaka)_

## Verification baseline

- Engine verified: **Godot 4.7.2**, GL Compatibility renderer, runtime-built `Node3D` scene.
- Preservation inventory: player movement/jump/crouch/sprint/slide/mantle, touch aim/fire/reload/swap, rifle/pistol state, wave director, Raider AI/collisions, score/HP/respawn, radar, HUD editor, layout and settings saves.
- Collision policy: visual terrain and cosmetic dressing are independent; original gameplay collision remains on the simple static floor and structural bodies.
- Local Godot download was attempted on 2026-10-12 but the release CDN closed the SSL connection (`curl: (35) SSL_ERROR_SYSCALL`). No screenshot is claimed until the engine can actually render one. GitHub Actions remains the authoritative import/export/headless runtime gate.

## Work packages

- [x] WP1 — filmic PBR lighting, warm key/cool fill, soft directional shadows, SSAO fallback and capped lamps.
- [x] WP8 — filmic tone map, grading, bloom, FXAA project setting; per-tier presentation hooks.
- [x] WP2 — procedural sky, sun disc, layered horizon dust, fog and wave atmosphere transitions, ambient dust/embers.
- [x] WP3 — high-density visual terrain, PBR detail maps, pads/routes, deterministic rocks/drums scatter, stratified mesas.
- [x] WP4 — detailed outpost kit: windows, frames, trim, roof clutter, containers, railings, ladder, fence wire, watchtower, readable sign, emissive spill.
- [x] WP5 — Raider procedural articulated character variants, tactical variants/nameplates, aim/fire/reload-like poses, hit/death and footstep dust.
- [x] WP6 — detailed first-person weapons/hands, viewmodel fallback, breathing/sway/recoil/reload/swap presentation and muzzle lights.
- [x] WP7 — pooled tracers, smoke, casings, surface-aware impacts/decals, ambient dust/embers and enemy footstep particles.
- [x] WP9 — glass/outlined icon HUD/control reskin, graphical vitals/ammo, dynamic reticle feedback, restyled radar and non-overlap defaults.
- [x] WP10 — operation loading splash.
- [x] WP11 — AUTO/LOW/MEDIUM/HIGH/ULTRA selection, first-launch auto-detect, dynamic 3D resolution and adaptive presentation governor.
- [x] Screenshot set — genuine renderer captures are committed under `screenshots/before/` and `screenshots/after/`; the CI harness refreshes all 12 required views including explicit 15 m and 5 m Raider frames.
- [x] Post-package visual polish — terrain normals/height variation, visible window frames, readable sign plaque, weathering scatter/tyre tracks, non-overlapping circular defaults, dynamic crosshair, layered weapon flash, and a more readable Raider tactical front/shouldered-carbine silhouette are rendered in the refreshed genuine after set.
- [ ] Final physical Android validation (the hosted emulator has an infrastructure boot timeout).

## Next continuation point

The complete source/render work is committed and CI-rendered. The latest full visual candidate is #48 from commit `b6db62c`; its source, Android export, headless startup and all 12 real before/after renderer captures passed. The hosted Android emulator timed out while booting, so a physical Android playthrough is the only remaining gate before a physical-device-final label.
