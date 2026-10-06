# Operation Redline — test report

**Date:** 2026-10-06

**Build candidate:** Source revision in this repository (no Android binary produced yet)

**Status:** **Source checks passed; Android APK gate blocked by missing local export toolchain.**

## Passed checks

| Check | Command / method | Result |
| --- | --- | --- |
| Original texture dimensions | `python3 tools/validate_project.py` reads PNG IHDR headers | **PASS** — 4 textures, all exactly 128×128 |
| Referenced-resource consistency | `python3 tools/validate_project.py` scans committed `res://` references | **PASS** — 7 resource links resolve |
| GDScript parse/type diagnostics | `npm ci && npm run test:gdscript` via pinned Godot 4.x analyzer | **PASS** — 6 scripts, 0 errors, 0 warnings |
| Startup scene presence | Same validator checks `project.godot` and `scenes/Main.tscn` | **PASS** |
| C++ warning-clean compile | `g++ -std=c++20 -Wall -Wextra -Werror -pedantic ...` | **PASS** |
| C++ survival pacing unit tests | `./scripts/run_native_tests.sh` | **PASS** — waves 1–3, 27 spawns, wave clear, completion state, stopped-state invariant |
| Repository artifact size | `find ... -size +1M` | **PASS** — no large generated binary was placed in source control |

## Remote Android build gate

`.github/workflows/android-apk.yml` is the reproducible remote build/test lane. On a push to the Arena branch or a manual GitHub Actions dispatch it installs Godot 4.7.2 plus export templates, exports the arm64/x86_64 debug APK, verifies the archive/signature, installs it in an API 35 x86_64 Android emulator, launches the package, scans the launch log for fatal Android errors, and uploads the APK plus log as a workflow artifact. The workflow must finish green before its artifact is called a tested APK.

**Current remote-run status:** The workflow file is active on GitHub, but this Arena GitHub integration received `HTTP 403: Resource not accessible by integration` when attempting `workflow_dispatch`; no workflow run or APK artifact exists yet. The account connection needs GitHub Actions dispatch permission (or the user can manually run **Build and verify Android APK** from the repository’s Actions tab on `arena/e2b9c124-2d-game`).

## Not yet executable in this local environment

| Gate | Why it cannot be marked passed | Required before handoff |
| --- | --- | --- |
| Godot import / GDScript parse | No Godot executable was installed in the supplied sandbox. Download attempts for Godot 4.7.2 reached GitHub metadata but the release-asset TLS connection was terminated before the binary could download. | Run project import and `godot --headless --path . --editor --quit` after a Godot 4.7+ editor is installed. |
| Android export | Android SDK, NDK, JDK, Gradle and Godot Android export templates are absent. | Configure the documented Android toolchain and run the **Android Debug** export preset. |
| APK install / launch | No APK exists yet and `adb` is absent. | Install with `adb install -r`, launch the package, complete all three waves with touch controls, then record device/emulator model, Android version, FPS and results here. |

## APK release rule

The file `build/OperationRedline-debug.apk` may only be called **tested** after all rows below are recorded as pass:

- Godot startup scene imports and runs without parse/runtime errors.
- Android debug export completes with a signed APK.
- APK archive/package ID are inspected.
- APK installs and launches on an Android emulator or physical arm64 device.
- Player movement/look, fire, reload, aim, enemy damage, all three waves, success screen and restart are manually exercised.
- No blocking error occurs during a 10-minute play session.

Until those gates pass, this report deliberately does **not** claim an APK is available or tested.
