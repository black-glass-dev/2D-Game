# Operation Redline — Graphics Overhaul Progress

_Last updated: 2026-10-12 (Asia/Dhaka)_

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
- [x] Screenshot set — genuine renderer captures are committed under `screenshots/before/` and `screenshots/after/`; the CI harness will refresh all 12 required views including 15 m and 5 m Raider comparisons on the next visual build.
- [ ] Final physical Android validation (the hosted emulator has an infrastructure boot timeout).

## Next continuation point

All code work packages are committed. Wait for the CI import/export/headless runtime result from the latest visual code commit. Then capture real landscape before/after screenshots on a functioning renderer/device into `screenshots/before/` and `screenshots/after/`, audit the Section 8 viewpoints, update `GRAPHICS_REPORT.md`, and only then make a physical-device-final claim.
