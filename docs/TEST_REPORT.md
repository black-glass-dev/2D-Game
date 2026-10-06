# Operation Redline — test report

**Date:** 2026-10-06

**Build candidate:** Source revision in this repository (no Android binary produced yet)

**Status:** **Source checks passed; Android APK gate blocked by missing local export toolchain.**

## Passed checks

| Check | Command / method | Result |
| --- | --- | --- |
| Original texture dimensions | `python3 tools/validate_project.py` reads PNG IHDR headers | **PASS** — 4 textures, all exactly 128×128 |
| Referenced-resource consistency | `python3 tools/validate_project.py` scans committed `res://` references | **PASS** — 7 resource links resolve |
| Startup scene presence | Same validator checks `project.godot` and `scenes/Main.tscn` | **PASS** |
| C++ warning-clean compile | `g++ -std=c++20 -Wall -Wextra -Werror -pedantic ...` | **PASS** |
| C++ survival pacing unit tests | `./scripts/run_native_tests.sh` | **PASS** — waves 1–3, 27 spawns, wave clear, completion state, stopped-state invariant |
| Repository artifact size | `find ... -size +1M` | **PASS** — no large generated binary was placed in source control |

## Not yet executable in this environment

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
