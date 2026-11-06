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
- `native/include/route_topology.hpp`
- `native/src/route_topology.cpp`
- `native/tests/operation_core_test.cpp`
- `native/tests/route_topology_test.cpp`

These engine-independent cores are appropriate for a Godot GDExtension or Android NDK compilation. They have no engine, renderer or platform dependencies, so survival state and future map-route topology can be unit-tested deterministically. `RouteTopology` deliberately contains no Highrise coordinates or endpoints until the authoritative B2 packet is staged. `scripts/wave_director.gd` is the current Godot scene adapter and mirrors the survival contract while an Android GDExtension binary is not yet built.

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

Before opening the project, run the headless source checks:

```bash
npm ci
npm run test:gdscript
python3 tools/validate_project.py
./scripts/run_native_tests.sh
```

`npm run test:gdscript` uses a pinned Godot 4.x GDScript static analyzer. It catches parser/type diagnostics without requiring a Godot editor; it does not replace a real scene launch or Android device test.

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

A reproducible GitHub Actions lane is included at [`.github/workflows/android-apk.yml`](.github/workflows/android-apk.yml). It runs source checks, exports this exact Android preset, checks the APK archive/signature, launches normal-Boot/renderer gates, and attempts install/launch on the documented API-29/default x86_64 hosted probe. A new downloadable candidate is published only when all of those gates, including Android install/launch, succeed. Artifact storage or an emulator timeout is not an APK delivery.

## Unity migration

The forward engine target is Unity under [`unity/`](unity/). Following the user's report that two successive Unity review APKs remained frozen/nonfunctional, the former procedural migration runtime is now retained only as an audit/reference record and is no longer started by the Bootstrap scene. A **clean Unity rebuild** now starts from [`Assets/RedlineRebuild/`](unity/Assets/RedlineRebuild/): a UGUI/EventSystem-owned Home → Desert → Pause → Results loop, direct Move/Look/Fire pointer surfaces, CharacterController movement, unscaled simulation, immediate visible contacts, three combat waves, raycast fire/reload, enemy pursuit, application-focus pause, and explicit live `WAVE`/`CONTACTS`/`HP`/`SIM` telemetry. It uses the project's Android-safe shader and temporary source-owned ground/concrete/metal/crate assets; later player-supplied art is planned as a manifest/prefab replacement seam rather than another control rewrite. The complete restart plan, batch order, asset boundary, and progress gates are in [`docs/UNITY_REBUILD_PLAN.md`](docs/UNITY_REBUILD_PLAN.md). Protected [run 42174955399](https://github.com/black-glass-dev/2D-Game/actions/runs/42174955399) built the first clean-runtime package: [Unity human-review `56f01d882dd5`](https://github.com/black-glass-dev/2D-Game/releases/tag/unity-human-review-56f01d882dd5), SHA-256 `939b3266e851e1e80a8b4e9955af5d8235396d54e74a44f1a94758153affc359`. It is explicitly unvalidated and still requires physical Android evidence. Unity licensing continues to use only masked GameCI `UNITY_EMAIL` and `UNITY_PASSWORD` references; no credential values are stored or printed.

## Verification status

See [`docs/TEST_REPORT.md`](docs/TEST_REPORT.md), [`docs/RELEASE_GATING.md`](docs/RELEASE_GATING.md), [`docs/PHYSICAL_DEVICE_QA.md`](docs/PHYSICAL_DEVICE_QA.md), and [`docs/PHYSICAL_ANDROID_HANDOFF.md`](docs/PHYSICAL_ANDROID_HANDOFF.md) for the exact evidence boundary. An APK must not be labelled **tested** until the Godot Android toolchain generates it, install/launch validation is recorded, and the required device matrix evidence exists.

**Do not use historical candidate 87 as a game handoff.** A real Android screenshot showed raw translation keys and an empty map list, so [`docs/MOBILE_TEST_APK_HANDOFF.md`](docs/MOBILE_TEST_APK_HANDOFF.md) withdraws it and records its immutable audit identity. The repaired source has an exported-PCK menu-content gate and requests a separately labelled, explicitly unvalidated human-review build; that future build is still not a tested/supported delivery until the stated emulator and physical-device boundaries are satisfied.

## Asset provenance

The game combines project-authored 128×128 pixel-art textures/runtime kits with small, period-appropriate CC0 subsets: **Kenney** conventional pistols/carbines, industrial outpost walls/roofs, barriers, fuel drums and desert dressing; and **KayKit** rigged low-poly human bases for the hostile smugglers. The exact source paths, pinned source revisions and CC0 terms are retained in [`assets/third_party/kenney_cc0/README.md`](assets/third_party/kenney_cc0/README.md) and [`assets/third_party/kaykit_cc0/README.md`](assets/third_party/kaykit_cc0/README.md); see [`CREDITS.md`](CREDITS.md) for concise credit. No commercial-game or science-fiction asset kit is used.

## Repository layout

```text
assets/       Original 128×128 textures, CC0 Kenney outpost kit and application icon
scenes/       Godot startup scene
scripts/      Player, combat, enemy, world and HUD scripts
native/       Portable C++20 survival core and unit tests
tools/        Reproducible asset generator and consistency validator
docs/         Product plan and test evidence
```
