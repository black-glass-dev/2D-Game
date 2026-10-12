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
- [ ] WP5 — Raider procedural articulated character variants and motion polish.
- [ ] WP6 — detailed first-person weapons/hands and presentation pass.
- [ ] WP7 — combat/ambient VFX expansion and surface-aware impacts.
- [ ] WP9 — final AAA HUD/control reskin and safe layout rules.
- [ ] WP10 — loading/menu polish.
- [ ] WP11 — four-tier selector, auto-detect and richer adaptive performance controls.
- [ ] Screenshot set — blocked pending a functioning Godot renderer; never substituted with mock images.
- [ ] Final regression and physical Android validation.

## Next continuation point

Implement WP5 in `scripts/enemy.gd`, then WP6/WP7 in `scripts/rifle.gd`, `scripts/pistol.gd`, and `scripts/weapon_effects.gd`. Re-run the static/project/native checks before every commit and use GitHub Actions for engine import/export/headless execution.
