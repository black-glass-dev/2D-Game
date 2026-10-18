# Operation Redline — test report

**Historical baseline date:** 2026-10-14 (Asia/Dhaka)

## Current delivery status — 2026-10-18

**No APK is currently offered by this project as a tested or supported downloadable delivery.** The forward workflow policy now requires source/export/normal-Boot/renderer success **and** Android emulator install/launch success before it can publish a new pre-release. CI run [39109089804](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39109089804) passed every non-device gate for `a980410`, then timed out at hosted-emulator boot and correctly skipped publication. Artifact storage remains quota-blocked.

The old [candidate #61](https://github.com/islamyousuf032-glitch/2D-Game/releases/tag/apk-candidate-61) is a retained historical pre-release record, not a current recommended delivery and not physical-device-tested. Its historical source/export/renderer evidence remains below for audit only. The current gate and exact evidence boundary are in [`RELEASE_GATING.md`](RELEASE_GATING.md).

## Passed checks

| Check | Command / method | Result |
| --- | --- | --- |
| Original texture dimensions | `python3 tools/validate_project.py` reads PNG IHDR headers | **PASS** — 4 retained retro textures are exactly 128×128; the new generated PBR/detail textures are separate 512×512 presentation assets |
| Referenced-resource consistency | `python3 tools/validate_project.py` scans committed `res://` references | **PASS** — 54 resource links resolve, including the curated CC0 model subset and the Highrise input contract |
| Highrise coordinate-packet contract | `python3 tools/validate_highrise_manifest.py` and `python3 tools/test_validate_highrise_manifest.py` | **PASS** — current map remains locked/no-coordinate; 3 dependency-free tests exercise waiting-state rejection and staged source/hash/anchor validation with temporary synthetic fixtures |
| GDScript parse/type diagnostics | `npm ci && npm run test:gdscript` via pinned Godot 4.x analyzer | **PASS** — 23 scripts, 0 errors, 0 warnings |
| C++ warning-clean compile | `g++ -std=c++20 -Wall -Wextra -Werror -pedantic ...` | **PASS** |
| C++ survival pacing unit tests | `./scripts/run_native_tests.sh` | **PASS** — 3 waves, 27 spawns and completion state |
| C++ route-topology unit tests | `./scripts/run_native_tests.sh` | **PASS** — validates generic registration, directionality, disabled traversal, fallback route, and unknown-endpoint behavior without map coordinates |
| Godot project import | GitHub Actions Godot 4.7.2 headless import | **PASS** |
| Gameplay scene startup | `godot --headless --path . --quit-after 180` | **PASS** — main scene starts without a parse/runtime stop |
| Renderer graphics evidence | Godot 4.7.2 + OpenGL llvmpipe/Xvfb capture harness | **PASS** — 12 genuine `before` and 12 genuine `after` PNGs, including spawn, lane, crate, sign, horizon, 15 m/5 m Raider, weapon, ADS, firing, low-HP and reload/crouch states |
| Android debug export | Godot Android Debug preset | **PASS** — arm64/x86_64 APK exported |
| APK archive and signature | `unzip -t` and `jarsigner -verify -certs -verbose` | **PASS** |
| Graphics gameplay-regression safety | Original visual collision remains separate; local checks plus CI headless startup exercise scene creation without changing player/wave/AI/HUD save paths | **PASS** |

## Historical APK and graphics evidence

- Historical pre-release candidate #61: [`OperationRedline-debug.apk`](https://github.com/islamyousuf032-glitch/2D-Game/releases/download/apk-candidate-61/OperationRedline-debug.apk). It is retained for audit only and must not be represented as a current tested delivery.
- Candidate #61 retains the persistent `SINGLE` / `AUTO` HUD selector beside the FIRE cluster. SINGLE preserves one shot per FIRE press; AUTO uses hold-to-fire while retaining each weapon's existing cooldown, ammunition, recoil and damage logic.
- Manual LOW, MEDIUM, HIGH and ULTRA selection is locked exactly at the player-selected visual budget. Only AUTO is allowed to temporarily adapt after sustained frame pressure. Tier changes visibly affect 3D render scale, shadow range, SSAO/bloom, lamps, scatter meshes, dust and embers without changing game simulation.
- Candidate #61 retains the repaired carbine ADS route: one main-camera world render, a 75→40° cubic FOV transition, 0.45× retained look sensitivity, transparent screen-space glass and an open reflex viewmodel below the reticle. The sidearm uses the same safe route at 55°. There is no mobile scope SubViewport, opaque black panel or filled black lens.
- Candidate #61 uses conventional Kenney CC0 models for service weapons, garage/window/roof modules, barriers, fuel drums, field sheet-metal and desert rocks, plus a KayKit CC0 human smuggler rig. The vendored KayKit derivative retains only the three gameplay clips and removes source medieval/exaggerated-head meshes before import, reducing the character package from 3.6 MB to 2.4 MB. Exact source pins, paths and CC0 terms are recorded in [`assets/third_party/kenney_cc0/README.md`](../assets/third_party/kenney_cc0/README.md) and [`assets/third_party/kaykit_cc0/README.md`](../assets/third_party/kaykit_cc0/README.md); no sci-fi, alien, blaster, space or commercial-game material is included.
- Genuine current renderer frames are versioned in [`screenshots/before/`](../screenshots/before/) and [`screenshots/after/`](../screenshots/after/), including the close/mid Raider frames and repaired `09_ads.png` frame. The implementation and fallback/tier record is in [`GRAPHICS_REPORT.md`](../GRAPHICS_REPORT.md); asset provenance is recorded in [`CREDITS.md`](../CREDITS.md).
- Candidate #61 completed source/static, C++ core, Godot import/export, APK signature, headless launch and all 12 genuine before/after capture gates in GitHub Actions run [`38519953827`](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38519953827). The runner failed only at its Android-emulator install/launch stage after emulator boot trouble; it still published the signed debug APK and build evidence.
- Candidate #15 established the persistent debug signing certificate and monotonically increasing Android version code. Candidate #61 uses that same certificate and its newer version code, so it directly updates candidates #15 through #60 in place; only #14-and-earlier candidates require one final uninstall.

## Physical-device gate

The GitHub-hosted Android emulator did not boot before its timeout. That is runner infrastructure failure, not an APK/export/signature failure. A prior physical-device screenshot verified the legacy signing stream, but candidate #61's expanded graphics, external assets and touch presentation still need a real-device playthrough before a fully physical-device-tested label can be used.

## APK release and physical-device rule

A future pre-release may be published only after the forward gate in [`RELEASE_GATING.md`](RELEASE_GATING.md) has passed Android emulator install/launch in addition to source, export, normal-Boot, and renderer gates. It may be labelled **physical-device-tested** only after a real Android device or working emulator completes the exact PASS/FAIL/BLOCKED evidence matrix in [`PHYSICAL_DEVICE_QA.md`](PHYSICAL_DEVICE_QA.md), with a completed copy of [`physical_qa_evidence.template.json`](physical_qa_evidence.template.json). Until then, there is no tested APK delivery claim.
