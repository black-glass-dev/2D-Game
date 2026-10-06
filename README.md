# Operation Redline

**Operation Redline** is an original, offline single-player first-person enemy-wave survival game for Android. You are holding a present-day desert military outpost after interrupting a smuggling operation. Three escalating waves of armed raiders approach through different lanes; protect the outpost, reload between waves, and secure the cargo.

> This project takes *retro 128×128 pixel texture art* as its visual rule. It is not a Call of Duty clone and contains no copied names, art, maps, audio, characters, or other assets from Call of Duty.

## First-playable scope

- First-person rifle combat: hitscan fire, muzzle flash, recoil, magazine/reload timing, hit confirmation and damage feedback.
- Android landscape controls: left-side movement drag, right-side look drag, plus visible **FIRE**, **RELOAD** and **AIM** controls. Keyboard/mouse controls work for development.
- A layered military outpost: raised yard, command building, depot, watchtower, perimeter lanes, cargo cover, lamp pools, distant mesas, fog and directional shadows.
- Three survival waves: **6 + 9 + 12** raiders, scoring, wave intermissions, mission success/failure and restart flow.
- Original procedural low-poly models and four authored 128×128 textures. Texture source is reproducible with `tools/generate_assets.py`.

## C++ design

The wave pacing / survival-state rules are written in portable C++20 in `native/`:

- `native/include/operation_core.hpp`
- `native/src/operation_core.cpp`
- `native/tests/operation_core_test.cpp`

This engine-independent core is appropriate for a Godot GDExtension or Android NDK compilation. It has no engine, renderer or platform dependencies, so its critical state transitions can be unit-tested deterministically. `scripts/wave_director.gd` is the current Godot scene adapter and mirrors this tested contract while an Android GDExtension binary is not yet built.

Run the native tests:

```bash
./scripts/run_native_tests.sh
```

## Run the game in Godot

This repository targets **Godot 4.7+** with the GL Compatibility/mobile renderer. Open `project.godot` and run the `Main` scene.

Desktop development controls:

| Input | Action |
| --- | --- |
| W A S D | Move |
| Mouse | Look |
| Left mouse | Fire |
| Right mouse or AIM | Aim |
| RELOAD button | Reload |
| Escape | Release mouse cursor |

Before opening the project, run the source-only consistency check:

```bash
python3 tools/validate_project.py
```

## Android debug APK export

`export_presets.cfg` contains an **Android Debug** arm64 preset with the output path `build/OperationRedline-debug.apk`.

1. Install a matching Godot 4.7+ editor and its Android export templates.
2. Configure Godot Editor Settings with a JDK 17+ path and Android SDK/NDK paths. Install an Android platform, build-tools and platform-tools through Android Studio or `sdkmanager`.
3. Open this project once so Godot imports the generated PNG/SVG assets.
4. Export from **Project → Export → Android Debug**, or run:

   ```bash
   godot --headless --path . --export-debug "Android Debug" build/OperationRedline-debug.apk
   ```

5. Validate the generated APK before sharing it:

   ```bash
   adb install -r build/OperationRedline-debug.apk
   adb shell monkey -p com.operationredline.outpost 1
   ```

The APK is intentionally ignored by Git. Source, export preset, asset generator, native tests and test report remain versioned.

## Verification status

See [`docs/TEST_REPORT.md`](docs/TEST_REPORT.md) for the exact checks run, passed results, and the outstanding Android-export gate. An APK must not be labelled **tested** until the Godot Android toolchain generates it and install/launch validation is recorded.

## Repository layout

```text
assets/       Original 128×128 textures and application icon
scenes/       Godot startup scene
scripts/      Player, combat, enemy, world and HUD scripts
native/       Portable C++20 survival core and unit tests
tools/        Reproducible asset generator and consistency validator
docs/         Product plan and test evidence
```
