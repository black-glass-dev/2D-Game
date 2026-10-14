# Operation Redline — test report

**Date:** 2026-10-13 (Asia/Dhaka)

**Current candidate:** [Operation Redline debug APK candidate #56](https://github.com/islamyousuf032-glitch/2D-Game/releases/tag/apk-candidate-56) (`OperationRedline-debug.apk`, 67,204,037 bytes)

**Status:** **Source checks, Godot import, Android export/signature, headless gameplay startup and real renderer screenshot capture passed. Candidate #56 retains persistent mobile SINGLE/AUTO fire selection, locked manual quality tiers and the verified no-black-panel ADS repair, and adds the CC0 period-appropriate outpost, weapon and human-smuggler asset pass. It is downloadable as an in-place debug update; the GitHub-hosted Android emulator itself timed out booting, so this build is not labelled as a fully physical-device-tested final release.**

## Passed checks

| Check | Command / method | Result |
| --- | --- | --- |
| Original texture dimensions | `python3 tools/validate_project.py` reads PNG IHDR headers | **PASS** — 4 retained retro textures are exactly 128×128; the new generated PBR/detail textures are separate 512×512 presentation assets |
| Referenced-resource consistency | `python3 tools/validate_project.py` scans committed `res://` references | **PASS** — 18 resource links resolve |
| GDScript parse/type diagnostics | `npm ci && npm run test:gdscript` via pinned Godot 4.x analyzer | **PASS** — 13 scripts, 0 errors, 0 warnings |
| C++ warning-clean compile | `g++ -std=c++20 -Wall -Wextra -Werror -pedantic ...` | **PASS** |
| C++ survival pacing unit tests | `./scripts/run_native_tests.sh` | **PASS** — 3 waves, 27 spawns and completion state |
| Godot project import | GitHub Actions Godot 4.7.2 headless import | **PASS** |
| Gameplay scene startup | `godot --headless --path . --quit-after 180` | **PASS** — main scene starts without a parse/runtime stop |
| Renderer graphics evidence | Godot 4.7.2 + OpenGL llvmpipe/Xvfb capture harness | **PASS** — 12 genuine `before` and 12 genuine `after` PNGs, including spawn, lane, crate, sign, horizon, 15 m/5 m Raider, weapon, ADS, firing, low-HP and reload/crouch states |
| Android debug export | Godot Android Debug preset | **PASS** — arm64/x86_64 APK exported |
| APK archive and signature | `unzip -t` and `jarsigner -verify -certs -verbose` | **PASS** |
| Graphics gameplay-regression safety | Original visual collision remains separate; local checks plus CI headless startup exercise scene creation without changing player/wave/AI/HUD save paths | **PASS** |

## Current APK and graphics evidence

- Downloadable candidate #56: [`OperationRedline-debug.apk`](https://github.com/islamyousuf032-glitch/2D-Game/releases/download/apk-candidate-56/OperationRedline-debug.apk)
- Candidate #56 retains the persistent `SINGLE` / `AUTO` HUD selector beside the FIRE cluster. SINGLE preserves one shot per FIRE press; AUTO uses hold-to-fire while retaining each weapon's existing cooldown, ammunition, recoil and damage logic.
- Manual LOW, MEDIUM, HIGH and ULTRA selection is now locked exactly at the player-selected visual budget. Only AUTO is allowed to temporarily adapt after sustained frame pressure. Tier changes now visibly affect 3D render scale, shadow range, SSAO/bloom, lamps, scatter meshes, dust and embers without changing game simulation.
- Candidate #56 retains the repaired carbine ADS route: one main-camera world render, a 75→40° cubic FOV transition, 0.45× retained look sensitivity, transparent screen-space glass and an open reflex viewmodel below the reticle. The sidearm uses the same safe route at 55°. There is no mobile scope SubViewport, opaque black panel or filled black lens.
- Candidate #56 uses conventional Kenney CC0 models for service weapons, garage/window/roof modules, barriers, fuel drums, field sheet-metal and desert rocks, plus KayKit CC0 human smuggler bases. Exact source pins, paths and CC0 terms are recorded in [`assets/third_party/kenney_cc0/README.md`](../assets/third_party/kenney_cc0/README.md) and [`assets/third_party/kaykit_cc0/README.md`](../assets/third_party/kaykit_cc0/README.md); no sci-fi, alien, blaster, space or commercial-game material is included.
- Genuine renderer frames are versioned in [`screenshots/before/`](../screenshots/before/) and [`screenshots/after/`](../screenshots/after/), including the repaired `09_ads.png` frame. The implementation and fallback/tier record is in [`GRAPHICS_REPORT.md`](../GRAPHICS_REPORT.md); asset provenance is recorded in [`CREDITS.md`](../CREDITS.md).
- Candidate #56 completed source/static, C++ core, Godot import/export, APK signature, headless launch and genuine before/after capture gates in GitHub Actions run [`38512135217`](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38512135217). The runner failed only at its Android-emulator install/launch stage after emulator boot trouble; it still published the signed debug APK and build evidence.
- Candidate #15 established the persistent debug signing certificate and monotonically increasing Android version code. Candidate #56 is in that same signing stream, so it directly updates candidate #15 through #54; only #14-and-earlier candidates require one final uninstall.

## Physical-device gate

The GitHub-hosted Android emulator did not boot before its timeout. That is runner infrastructure failure, not an APK/export/signature failure. A prior physical-device screenshot verified the legacy stream, but candidate #34's expanded graphics and touch presentation still need a real-device playthrough before a fully physical-device-tested label can be used.

## APK release rule

The APK may be labelled **fully tested** only after a physical Android or working-emulator playthrough checks: landscape presentation; touch look/movement; JUMP/CROUCH/SPRINT/SLIDE; FIRE/AIM/RELOAD/SWAP; saved HUD layout; settings tiers; radar; Raider combat; death/redeploy; and all three survival waves. Until then, releases remain deliberately labelled **debug candidate**.
