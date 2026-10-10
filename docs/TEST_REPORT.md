# Operation Redline — test report

**Date:** 2026-10-10

**Current candidate:** [Operation Redline debug APK candidate #15](https://github.com/islamyousuf032-glitch/2D-Game/releases/tag/apk-candidate-15) (`OperationRedline-debug.apk`)

**Status:** **Build, signature, source checks and headless gameplay startup passed. The latest APK is a downloadable debug candidate; Android emulator boot infrastructure did not complete, so it is not labelled as a fully tested final release.**

## Passed checks

| Check | Command / method | Result |
| --- | --- | --- |
| Original texture dimensions | `python3 tools/validate_project.py` reads PNG IHDR headers | **PASS** — 4 textures, all exactly 128×128 |
| Referenced-resource consistency | `python3 tools/validate_project.py` scans committed `res://` references | **PASS** — 7 resource links resolve |
| GDScript parse/type diagnostics | `npm ci && npm run test:gdscript` via pinned Godot 4.x analyzer | **PASS** — 7 scripts, 0 errors, 0 warnings |
| C++ warning-clean compile | `g++ -std=c++20 -Wall -Wextra -Werror -pedantic ...` | **PASS** |
| C++ survival pacing unit tests | `./scripts/run_native_tests.sh` | **PASS** — 3 waves, 27 spawns and completion state |
| Godot project import | GitHub Actions Godot 4.7.2 headless import | **PASS** |
| Gameplay scene startup | `godot --headless --path . --quit-after 180` | **PASS** — main scene runs without a parse/runtime stop |
| Android debug export | Godot Android Debug preset | **PASS** — arm64/x86_64 APK exported |
| APK archive and signature | `unzip -t` and `jarsigner -verify -certs -verbose` | **PASS** |
| Physical-device launch evidence | User-supplied Android screenshot of candidate #14 on 2026-10-10 | **PASS** — landscape gameplay, redesigned map and HUD editor launched on a real device; the screenshot exposed the joystick visual-resize defect fixed in candidate #15 |

## Current APK and test evidence

- Downloadable candidate #15: [`OperationRedline-debug.apk`](https://github.com/islamyousuf032-glitch/2D-Game/releases/download/apk-candidate-15/OperationRedline-debug.apk)
- Candidate #15 fixes HUD joystick scaling: its art, drag reach and touch movement radius now scale together when the player changes joystick size. It also gives FIRE a rounder, higher-contrast primary-action treatment.
- Candidate #15 establishes a persistent CI debug signing certificate and a monotonically increasing Android version code. Candidate #14 must be uninstalled once because it used a different, legacy generated certificate; later builds from this signing stream can be installed directly as updates over candidate #15.
- Candidate #15 completed the source, Android-export, APK/signature and headless-scene gates in GitHub Actions run [`38041925989`](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38041925989). The workflow also stores APK/log artifacts for each build run.

## Outstanding gate

The GitHub-hosted Android emulator did not boot before its timeout even after the package had built and the desktop headless scene launch had passed. This is an emulator-host infrastructure failure, not an APK export or signature failure. The next candidate should be checked on a physical Android device for movement, look drag, FIRE, RELOAD, AIM, three survival waves and restart before it is described as a fully tested final build.

## APK release rule

The APK may be labelled **fully tested** only after the complete touch-control playthrough (movement/look, fire, reload, aim, enemy damage, three waves, success/failure and restart) is recorded on a physical Android device or working emulator. Until then, releases are deliberately labelled **debug candidate**.
