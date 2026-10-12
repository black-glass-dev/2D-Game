# Operation Redline — test report

**Date:** 2026-10-12 (Asia/Dhaka)

**Current candidate:** [Operation Redline debug APK candidate #34](https://github.com/islamyousuf032-glitch/2D-Game/releases/tag/apk-candidate-34) (`OperationRedline-debug.apk`, 62,516,929 bytes)

**Status:** **Source checks, Godot import, Android export/signature, headless gameplay startup and real renderer screenshot capture passed. Candidate #34 is downloadable and installed as an in-place debug update; the GitHub-hosted Android emulator itself timed out booting, so this build is not labelled as a fully physical-device-tested final release.**

## Passed checks

| Check | Command / method | Result |
| --- | --- | --- |
| Original texture dimensions | `python3 tools/validate_project.py` reads PNG IHDR headers | **PASS** — 4 retained retro textures are exactly 128×128; the new generated PBR/detail textures are separate 512×512 presentation assets |
| Referenced-resource consistency | `python3 tools/validate_project.py` scans committed `res://` references | **PASS** — 16 resource links resolve |
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

- Downloadable candidate #34: [`OperationRedline-debug.apk`](https://github.com/islamyousuf032-glitch/2D-Game/releases/download/apk-candidate-34/OperationRedline-debug.apk)
- Candidate #34 carries the full original-art graphics pass: landscape-native canvas, filmic desert lighting, bloom/SSAO-compatible fallbacks, wave-driven haze, visual terrain and PBR detail maps, dressed outpost kit, articulated Raider variants, detailed weapon/hands presentation, pooled combat/atmosphere effects, glass-style touch HUD, loading splash, and AUTO/LOW/MEDIUM/HIGH/ULTRA adaptive quality controls.
- Genuine renderer frames are versioned in [`screenshots/before/`](../screenshots/before/) and [`screenshots/after/`](../screenshots/after/). The implementation and fallback/tier record is in [`GRAPHICS_REPORT.md`](../GRAPHICS_REPORT.md); CC0/asset provenance is recorded in [`CREDITS.md`](../CREDITS.md).
- Candidate #34 completed all gates above in GitHub Actions run [`38210844490`](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38210844490). The workflow stores the signed APK and build evidence artifacts for the run.
- Candidate #15 established the persistent debug signing certificate and monotonically increasing Android version code. Candidate #34 is in that same signing stream, so it directly updates candidate #15 through #33; only #14-and-earlier candidates require one final uninstall.

## Physical-device gate

The GitHub-hosted Android emulator did not boot before its timeout. That is runner infrastructure failure, not an APK/export/signature failure. A prior physical-device screenshot verified the legacy stream, but candidate #34's expanded graphics and touch presentation still need a real-device playthrough before a fully physical-device-tested label can be used.

## APK release rule

The APK may be labelled **fully tested** only after a physical Android or working-emulator playthrough checks: landscape presentation; touch look/movement; JUMP/CROUCH/SPRINT/SLIDE; FIRE/AIM/RELOAD/SWAP; saved HUD layout; settings tiers; radar; Raider combat; death/redeploy; and all three survival waves. Until then, releases remain deliberately labelled **debug candidate**.
