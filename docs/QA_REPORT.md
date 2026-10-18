# QA Report

## M0 baseline — 2026-10-14

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 13 scripts, 0 errors, 0 warnings | Terminal log in Recon batch |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 30 `res://` links and 4 128×128 textures | Terminal log in Recon batch |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion | Terminal log in Recon batch |
| Remote/workspace integrity | SHA-256 compare against `origin/arena/e2b9c124-2d-game` | PASS — every remote tracked file matched; only planned Recon documents differed | `docs/BASELINE_AUDIT.md` |
| Gameplay regression | No gameplay source edited in M0 Batch 1 | Not applicable yet | Documentation-only change set |

## M1 batch 1 — foundation contract

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 21 scripts, 0 errors, 0 warnings | M1 Batch 1 terminal log |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 45 `res://` links and 4 128×128 textures | M1 Batch 1 terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion | M1 Batch 1 terminal log |
| Whitespace | `git diff --check` | PASS | M1 Batch 1 terminal log |
| Godot import, Android debug export, and headless launch | GitHub Actions run 38589728753 | PASS | `https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38589728753` — import/export/headless/capture steps succeeded |
| Android emulator install/launch | GitHub Actions run 38589728753 | BLOCKED — emulator boot timeout | The APK candidate and build evidence uploaded, but the hosted emulator did not boot before timeout; this is not a device-pass result |

## M1 batch 2 / M2 entry flow — Boot shell

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 22 scripts, 0 errors, 0 warnings | M1 Batch 2 terminal log |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 48 `res://` links and 4 128×128 textures | M1 Batch 2 repair terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion | M1 Batch 2 repair terminal log |
| Asset manifest syntax and font hashes | `python3 -m json.tool assets_manifest.json`; `sha256sum` | PASS — manifest parses; Regular/SemiBold match the recorded hashes | M1 Batch 2 terminal log |
| Godot import and Android debug export | GitHub Actions run 38686284925 | PASS | `https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38686284925` — source tests, Godot import, and export succeeded on `6ee749e` |
| Actual Boot → `SceneLoader` → `Main.tscn` hand-off | Normal project launch with the test-only `--verify-boot-flow` user argument | PASS | [GitHub Actions run 38686284925](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38686284925) passed `Launch Boot and gameplay flow headlessly`; CI requires `BOOT_FLOW_PASS` in `godot-boot-flow.log` |
| Genuine gameplay graphics frames | CI OpenGL capture | PASS — 12 before + 12 after PNGs | `d8b4c61`; `screenshots/before/` and `screenshots/after/` |
| Android emulator install/launch | GitHub Actions run 38686284925 | BLOCKED — emulator boot timeout | Candidate #67 and build evidence uploaded, but the hosted emulator did not boot before timeout; this is not a device-pass result |

## M2 entry-flow repair — CI runs 38685720708 and 38686031938

| Finding | Status | Corrective action |
| --- | --- | --- |
| `MapRegistry` used a method call in a `const` expression, preventing its autoload from compiling | Fixed and verified | Use constant `res://data/maps`; extend the static validator to accept an existing resource directory for `DirAccess.open()`. |
| `MP_DS_01.tres` used array syntax inside `PackedStringArray`, causing a resource parse error | Fixed and verified | Use Godot text-resource `PackedStringArray("…", "…")` syntax. |
| Project settings attempted to load the raw CSV as a `Translation` resource | Fixed and verified | Remove the invalid setting and have `LocalizationService` parse the reviewed CSV and register `Translation` objects at runtime. |
| The first harness used Godot `--script`, which does not register project autoload singletons for dependent scene compilation | Fixed and verified | Launch the normal project with a test-only `--verify-boot-flow` user argument; Boot starts the real load and Main emits `BOOT_FLOW_PASS` only after it owns Playing state. |

Candidate #67 is not treated as a tested delivery because the Android emulator install/launch gate is still blocked.

## M2 batch 2 — settings surface

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M2 Batch 2 terminal log |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 48 `res://` links and 4 128×128 textures | M2 Batch 2 terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion | M2 Batch 2 terminal log |
| Godot import/export/headless settings route | Normal project launch with test-only `--verify-settings-menu` user argument | PASS | [GitHub Actions run 38744384858](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38744384858) passed the launch step; CI requires `SETTINGS_MENU_PASS` after instantiating the reusable menu and persisting/restoring an explicit quality value |
| Android emulator install/launch | GitHub Actions run 38744384858 | BLOCKED — emulator boot timeout | Candidate #68 was uploaded, but the hosted emulator did not boot before timeout; this is not a device-pass result |

## M2 batch 3 — map detail and future card

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M2 Batch 3 terminal log |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 48 `res://` links and 4 128×128 textures | M2 Batch 3 terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion | M2 Batch 3 terminal log |
| Locked Highrise map card | Normal project launch with `--verify-map-select` | PASS | [GitHub Actions run 38747901596](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38747901596) passed the headless launch step; CI requires `MAP_SELECT_PASS` only when `MP_RF_02` is registered, selectable for inspection, and cannot launch |
| Android emulator install/launch | GitHub Actions run 38747901596 | BLOCKED — emulator boot timeout | Candidate #69 was uploaded, but the hosted emulator did not boot before timeout; this is not a device-pass result |

## M3 batch 1 — pause lifecycle and visual evidence

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M3 Batch 1 terminal log and CI run 38754873297 source-test step |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 50 `res://` links and 4 128×128 textures | M3 Batch 1 terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion | M3 Batch 1 terminal log |
| Normal Boot → pause → shared settings → pause → resume route | Normal project launch with test-only `--verify-pause-flow` user argument | PASS | [GitHub Actions run 38754873297](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38754873297) passed `Launch Boot and gameplay flow headlessly`; it requires `PAUSE_FLOW_PASS` after checking `GameManager`/tree pause state, overlay visibility, shared-settings return, and resumed gameplay state. |
| Genuine pause and Bengali settings frames | Normal `Boot.tscn` launch under Xvfb/OpenGL with `--verify-pause-flow --capture-pause-bengali` | PASS — two 1280×720 PNGs | CI run 38754873297 passed `Capture pause and Bengali settings through normal Boot flow`; output paths are `build/screenshots/pause/pause-overlay.png` and `build/screenshots/pause/pause-settings-bn.png` in the `operation-redline-android-debug` build artifact. The sandbox could not download the Azure-backed artifact URL, so this records capture/size evidence rather than a local pixel review. |
| Godot import, debug APK export/signature, and graphics capture | CI pipeline | PASS | CI run 38754873297 passed import/export, APK archive/signature verification, and the 12-before/12-after renderer capture gate. |
| Android emulator install/launch | GitHub Actions run 38754873297 | BLOCKED — emulator boot timeout | The source/export/UI gates passed and a debug candidate was published, but the hosted emulator did not boot. This is not device-launch evidence. |

## M3 batch 2 — operation results and retry contract

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M3 Batch 2 terminal log and CI run 38759649992 source-test step |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 50 `res://` links and 4 128×128 textures | M3 Batch 2 terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion | M3 Batch 2 terminal log |
| Normal Boot → mission-complete result overlay → durable map record | Normal project launch with `--verify-result-flow` | PASS | [GitHub Actions run 38759649992](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38759649992) passed the headless launch gate. It requires `RESULT_FLOW_PASS` only after a real Main scene reaches `MISSION_COMPLETE`, creates the result panel, and writes/reads score 275 and wave 3 through `SaveService`. |
| Existing pause/settings visual regression | Normal Boot launch under Xvfb/OpenGL | PASS | CI run 38759649992 passed the pause overlay/Bengali settings capture step again, preserving the M3 Batch 1 visual route while result code was added. |
| Android emulator install/launch | GitHub Actions run 38759649992 | BLOCKED — emulator boot timeout | Source, import/export, result-flow, pause visual, and graphics gates passed; the hosted emulator timed out before boot. This is not device-launch evidence. |

## M3 batch 3 — audio buses and focus policy

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M3 Batch 3 terminal log and CI run 38846049446 source-test step |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 51 `res://` links and 4 128×128 textures | M3 Batch 3 terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion | M3 Batch 3 terminal log |
| Normal Boot → focus mute/restore → SFX/UI routing | Normal project launch with `--verify-audio-flow` | PASS | [GitHub Actions run 38846049446](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38846049446) passed the headless launch gate. It requires `AUDIO_FLOW_PASS` after verifying Master mute on focus loss, saved-volume-aware restore, SFX routing for rifle/pistol/landing, and UI-bus feedback availability. |
| Pause/settings visual regression | Normal Boot launch under Xvfb/OpenGL | PASS | CI run 38846049446 passed the real pause overlay/Bengali settings capture after the audio-routing change. |
| Android emulator install/launch | GitHub Actions run 38846049446 | BLOCKED — emulator boot timeout | Source, import/export, audio-flow, pause visual, and graphics gates passed; the hosted emulator timed out before boot. This is not device-launch evidence. |

## M3 batch 4 — live input and accessibility adapters

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M3 Batch 4 local terminal log; CI run 38859413030 source-test step |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 51 `res://` links and 4 128×128 textures | M3 Batch 4 local terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion state | M3 Batch 4 local terminal log |
| Whitespace | `git diff --check` | PASS | M3 Batch 4 local terminal log |
| Named input map and live accessibility contracts | Normal project launch with `--verify-input-accessibility-flow` | PASS | [GitHub Actions run 38859413030](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38859413030) passed the headless launch step. The gate requires `INPUT_ACCESSIBILITY_PASS` after checking 11 named actions have gamepad bindings and applying reduced motion, DEUTERANOPIA HUD colors, enabled/disabled floating damage numbers, haptics preference state, and runtime gamepad-deadzone application. |
| Existing Boot/audio/pause/result contracts | Normal project launch under the CI flow-gate suite | PASS | CI run 38859413030 passed all normal-Boot flow gates plus pause/Bengali settings capture after the adapter change. |
| Genuine renderer frames | Xvfb/OpenGL real-scene capture | PASS — 12 before + 12 after PNGs | CI run 38859413030 passed the full graphics capture. Commit `f9efcaf` records refreshed `screenshots/before/` and `screenshots/after/` evidence. |
| Android emulator install/launch | GitHub Actions run 38859413030 | BLOCKED — emulator boot timeout | The export, normal-Boot, pause, and renderer gates passed, but the hosted emulator did not boot before timeout. The candidate APK is not physical-device-tested delivery. |

## M3 batch 5 — live tactical sound captions

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M3 Batch 5 local terminal log; CI run 38872610433 source-test step |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 51 `res://` links and 4 128×128 textures | M3 Batch 5 local terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion state | M3 Batch 5 local terminal log |
| Whitespace | `git diff --check` | PASS | M3 Batch 5 local terminal log |
| Subtitle setting → tactical sound caption | Normal project launch with `--verify-input-accessibility-flow` | PASS | [GitHub Actions run 38872610433](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38872610433) passed the headless flow suite. The existing gate now requires `INPUT_ACCESSIBILITY_PASS` after verifying disabled captions stay hidden and enabled captions render the localized rifle-fire cue, alongside the prior input/accessibility checks. |
| Existing Boot/audio/pause/result contracts | Normal project launch under the CI flow-gate suite | PASS | CI run 38872610433 passed all normal-Boot gates and the pause/Bengali settings capture after caption wiring. |
| Genuine renderer frames | Xvfb/OpenGL real-scene capture | PASS — 12 before + 12 after PNGs | CI run 38872610433 passed the full capture; commit `2360443` records refreshed renderer evidence. |
| Android emulator install/launch | GitHub Actions run 38872610433 | BLOCKED — emulator boot timeout | Export and all headless/renderer gates passed, but the hosted emulator did not boot before timeout. |
| Tested-build evidence archive | GitHub Actions run 38872610433 | BLOCKED — Actions artifact-storage quota | GitHub reported `Failed to CreateArtifact: Artifact storage quota has been hit`; this is a CI-storage blocker, not an APK/device-pass result. |

## M3 batch 6 — Back navigation and pause-return contract

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M3 Batch 6 local terminal log; CI run 38875741554 source-test step |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 51 `res://` links and 4 128×128 textures | M3 Batch 6 local terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion state | M3 Batch 6 local terminal log |
| Whitespace | `git diff --check` | PASS | M3 Batch 6 local terminal log |
| Back notification, Escape, and controller-B routes | Normal project launch with `--verify-back-flow` | PASS | [GitHub Actions run 38875741554](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38875741554) passed the headless flow suite. The gate requires `BACK_FLOW_PASS` after native Android Back returns from Splash, Escape returns from Settings, controller B returns from Map Select, and both keyboard/gamepad menu-back bindings exist. |
| Paused-settings → resume with Android Back | Normal project launch with `--verify-pause-flow` | PASS | CI run 38875741554 passed `PAUSE_FLOW_PASS` after invoking `NOTIFICATION_WM_GO_BACK_REQUEST` to leave shared paused settings, then invoking it again to resume Desert. |
| Existing Boot/audio/result/input-accessibility contracts | Normal project launch under the CI flow-gate suite | PASS | CI run 38875741554 passed all normal-Boot gates, pause/Bengali settings capture, and full renderer capture after Back-route wiring. Commit `a92010a` records refreshed renderer frames. |
| Android emulator install/launch | GitHub Actions run 38875741554 | BLOCKED — emulator boot timeout | Export and all source/headless/renderer gates passed, but the hosted emulator did not boot before timeout. |
| Tested-build evidence archive | GitHub Actions run 38875741554 | BLOCKED — Actions artifact-storage quota | GitHub again reported `Failed to CreateArtifact: Artifact storage quota has been hit`; no build archive is presented as delivery. |

## M3 batch 7 — live touch-control preferences

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M3 Batch 7 local terminal log; CI run 38905133721 source-test step |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 51 `res://` links and 4 128×128 textures | M3 Batch 7 local terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion state | M3 Batch 7 local terminal log |
| Whitespace | `git diff --check` | PASS | M3 Batch 7 local terminal log |
| Live scale, opacity, left-handed and base-layout contract | Normal project launch with `--verify-control-layout-flow` | PASS | [GitHub Actions run 38905133721](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38905133721) passed the headless flow suite. The gate requires `CONTROL_LAYOUT_PASS` after joystick/button scale, touch opacity, left-handed placement, fixed minimap placement, and display-to-base layout preservation checks. |
| Existing Boot/audio/result/input-accessibility/Back contracts | Normal project launch under the CI flow-gate suite | PASS | CI run 38905133721 passed all normal-Boot gates, pause/Bengali settings capture, and full renderer capture after touch-preference wiring. Commit `58f5e97` records refreshed renderer frames. |
| Android emulator install/launch | GitHub Actions run 38905133721 | BLOCKED — emulator boot timeout | Export and all source/headless/renderer gates passed, but the hosted emulator did not boot before timeout. |
| Tested-build evidence archive | GitHub Actions run 38905133721 | BLOCKED — Actions artifact-storage quota | GitHub again reported `Failed to CreateArtifact: Artifact storage quota has been hit`; no build archive is presented as delivery. |

## M3 batch 8 — conflict-aware input rebinding

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M3 Batch 8 local terminal log; CI run 38914993211 source-test step |
| Localization CSV structure | Python `csv` reader and uniqueness assertions | PASS — 136 three-column, unique-key rows | M3 Batch 8 local terminal log |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 51 `res://` links and 4 128×128 textures | M3 Batch 8 local terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion state | M3 Batch 8 local terminal log |
| Whitespace | `git diff --check` | PASS | M3 Batch 8 local terminal log |
| Keyboard/gamepad capture, persistence, conflict, cancel, reset, and Controls rows | Normal project launch with `--verify-rebind-flow` | PASS | [GitHub Actions run 38914993211](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38914993211) passed `Launch Boot and gameplay flow headlessly`; CI requires `REBIND_FLOW_PASS` after a keyboard F10 capture/reload, gamepad L3 capture/reload, same-surface conflict rejection, two Controls rows, capture cancellation, and reset/default restoration. |
| Existing Boot/audio/result/input-accessibility/Back/control-layout contracts | Normal project launch under the CI flow-gate suite | PASS | CI run 38914993211 passed all normal-Boot gates, pause/Bengali settings capture, and full renderer capture. Commit `63bba34` records refreshed renderer frames. |
| Android emulator install/launch | GitHub Actions run 38914993211 | BLOCKED — emulator boot timeout | Source, import, export, signature, normal-Boot, and renderer gates passed, but the hosted emulator did not boot before timeout. This is not physical-device evidence. |
| Tested-build evidence archive | GitHub Actions run 38914993211 | BLOCKED — Actions artifact-storage quota | GitHub reported `Failed to CreateArtifact: Artifact storage quota has been hit`; no APK archive is presented as delivery. |

## M2 batch 9 — truthful loading telemetry

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M2 Batch 9 local terminal log; CI run 39013816812 source-test step |
| Localization CSV structure | Python `csv` reader and uniqueness assertions | PASS — 142 three-column, unique-key rows | M2 Batch 9 local terminal log |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 52 `res://` links and 4 128×128 textures | M2 Batch 9 local terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion state | M2 Batch 9 local terminal log |
| Whitespace | `git diff --check` | PASS | M2 Batch 9 local terminal log |
| Actual initial/loading/completion telemetry | Normal project launch with `--verify-loading-flow` | PASS | [GitHub Actions run 39013816812](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39013816812) passed the headless flow suite. The gate requires `LOADING_FLOW_PASS` after the zero-percent localized preparation screen, completed Main hand-off, 100-percent completion, elapsed time, and raw progress-sample telemetry checks. |
| Existing Boot/audio/result/input-accessibility/Back/control-layout/rebind contracts | Normal project launch under the CI flow-gate suite | PASS | CI run 39013816812 passed all normal-Boot gates, pause/Bengali settings capture, and full renderer capture. Commit `f33bca0` records refreshed renderer frames. |
| Android emulator install/launch | GitHub Actions run 39013816812 | BLOCKED — emulator boot timeout | Source, import, export, signature, normal-Boot, and renderer gates passed, but the hosted emulator did not boot before timeout. This is not physical-device evidence. |
| Tested-build evidence archive | GitHub Actions run 39013816812 | BLOCKED — Actions artifact-storage quota | GitHub reported `Failed to CreateArtifact: Artifact storage quota has been hit`; no APK archive is presented as delivery. |

## M2 batch 10 — Desert session compatibility adapter

| Test | Command / method | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | M2 Batch 10 local terminal log; CI run 39015842921 source-test step |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 52 `res://` links and 4 128×128 textures | M2 Batch 10 local terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion state | M2 Batch 10 local terminal log |
| Whitespace | `git diff --check` | PASS | M2 Batch 10 local terminal log |
| Difficulty cadence, Normal/Survival baseline, and Endless continuation | Normal project launch with `--verify-session-adapter-flow` | PASS | [GitHub Actions run 39015842921](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39015842921) passed the headless flow suite. The gate requires `SESSION_ADAPTER_PASS` after Boot passes HARD/ENDLESS into Main, verifies the 6/9/12/6 cycle, preserves Normal 0.83/0.71/0.59 cadence and three-wave completion, orders Easy/Normal/Hard/Nightmare cadence, and confirms Endless continues after wave three. |
| Existing Boot/audio/result/input-accessibility/Back/control-layout/rebind/loading contracts | Normal project launch under the CI flow-gate suite | PASS | CI run 39015842921 passed all normal-Boot gates, pause/Bengali settings capture, and full renderer capture. Commit `8bcb15b` records refreshed renderer frames. |
| Android emulator install/launch | GitHub Actions run 39015842921 | BLOCKED — emulator boot timeout | Source, import, export, signature, normal-Boot, and renderer gates passed, but the hosted emulator did not boot before timeout. This is not physical-device evidence. |
| Tested-build evidence archive | GitHub Actions run 39015842921 | BLOCKED — Actions artifact-storage quota | GitHub reported `Failed to CreateArtifact: Artifact storage quota has been hit`; no APK archive is presented as delivery. |

## M2 batch 11 — quality-aware menu backdrop (local source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | 2026-10-17 local terminal log |
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 53 `res://` links and 4 128×128 world textures | 2026-10-17 local terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion state | 2026-10-17 local terminal log |
| Menu-asset integrity | Python PNG/header + manifest SHA-256 check | PASS — `assets/ui/menu_desert_outpost.png`, 1024×576, 671107 bytes, SHA-256 `282f687f85d4f71960e95279536717123b437e0bd207ab8000b9c4fa1151c72c` | 2026-10-17 local terminal log |
| Whitespace | `git diff --check` | PASS | 2026-10-17 local terminal log |
| Normal-Boot quality selection | `--verify-menu-background-flow` | PASS — `AUTO`/`HIGH` selected `static_outpost`; explicit `LOW` selected `procedural_low` | CI run 39030720943; initial diagnostic log remains in `ci-logs/godot-menu-background-flow.log` |
| Normal-Boot renderer frames | Xvfb `--capture-menu-backgrounds` | PASS — named HIGH/LOW frames are valid, non-identical 1280×720 PNGs after Boot selected the intended paths | CI run 39030720943; committed at `630e9c2`: `screenshots/menu/menu_background_high.png` (490475 bytes, `dc30ba4a37d1a21d8b2affcfd1bb154ecd3632fd8e5147be0b37b11fccbf05c1`) and `menu_background_low.png` (32726 bytes, `e0926038c12720271849cdc9b47d6191e724158a312052994956297097db0544`) |

The LOW path is intentionally a texture-free `ColorRect` composition. The non-LOW path is a static original image. Both are Boot presentation only; this batch does not load `Main`, start a 3D background simulation, or alter Desert waves, score, HP, HUD, controls, input, loading, or Back routes. CI run 39030720943 passed all listed source/import/export/normal-Boot/Xvfb renderer gates, but the hosted Android emulator timed out before boot and artifact upload remained quota-blocked. It therefore does not qualify as a physical-device result or downloadable APK delivery.

## M3 batch 12 — original background music (source and normal-Boot gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Deterministic source asset | `python3 tools/generate_music.py --check` | PASS — committed PCM frames exactly match the source-controlled generator | 2026-10-17 local terminal log |
| Waveform boundary / clipping | Python PCM analysis | PASS — peak `10160/32767`; first/last 50-frame edge peak `157`, providing a click-safe forward-loop boundary | 2026-10-17 local terminal log |
| Music asset shape | `python3 tools/validate_project.py` | PASS — mono, 16-bit, 22,050 Hz, 352,800 frames / 16 seconds; generator check executes within project validation | 2026-10-17 local terminal log |
| GDScript static analysis | `npm run test:gdscript` | PASS — 23 scripts, 0 errors, 0 warnings | 2026-10-17 local terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion state | 2026-10-17 local terminal log |
| Music-bus loop, zero-volume stop, and resume | Normal project `--verify-audio-flow` | PASS — Music bus/player, forward-loop metadata, zero-volume stop, and non-zero resume passed inside the existing normal-Boot audio contract | [GitHub Actions run 39032788356](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39032788356), `Launch Boot and gameplay flow headlessly` step |
| Human listening / physical Android mix | Device headphone/speaker check | OPEN — hosted emulator again timed out before boot; no device evidence exists | `docs/AUDIO_ASSET_REVIEW.md` records source/mix analysis only |

The loop is a global `AudioService` player and does not change Desert score, HP, waves, enemy data, input, HUD layout, loading, map ownership, or Back routes. Its effective default bed is approximately -18.5 dB before Master volume, deliberately below existing transient combat effects. CI run 39032788356 passed every listed source/import/export/normal-Boot/Xvfb renderer gate, but its hosted Android emulator timed out before boot and artifact upload remained quota-blocked. This is a source/mix-policy and normal-Boot contract result, not an audible listening or physical-device claim.

## M3 batch 13 — downloadable APK truth gate (local source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Named Android device gate | Workflow source inspection | PASS — emulator step has stable `id: android_emulator` | `.github/workflows/android-apk.yml` |
| Candidate-release condition | `python3 tools/validate_project.py` | PASS — validator rejects a workflow that lacks `steps.android_emulator.outcome == 'success'` | 2026-10-17 local terminal log |
| Signing/update compatibility | Workflow review | PASS — existing package ID and persistent `operation-redline-debug.keystore` restore/cache path are unchanged | `.github/workflows/android-apk.yml`; `docs/RELEASE_GATING.md` |
| First failed-emulator publication skip | GitHub Actions run 39034299154 | PASS — Android emulator timed out; `Publish a device-validated debug APK candidate` was skipped and no `apk-candidate-88` release was created | [Run 39034299154](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39034299154); post-run `gh release list` still ended at `apk-candidate-87` |

Historical pre-releases are not physical-device-tested deliveries; this batch preserves them as audit records rather than deleting or relabelling them. The forward release gate now has CI evidence that it prevents a new downloadable candidate while the final Android install/launch step is failing.

## M3 batch 14 — physical-device QA handoff (documentation gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Complete physical-device matrix | Checklist review | READY — 12 identity/evidence-bound rows cover in-place install, landscape, touch, keyboard/mouse, gamepad, Back/focus, settings/language/quality, audio, survival, and thermal observations | `docs/PHYSICAL_DEVICE_QA.md` |
| Evidence record schema | JSON parse + project validator | PASS — template is valid JSON, defaults every row to `NOT_RUN`, and `tools/validate_project.py` now rejects a missing/misclassified/incomplete template | CI run 39102616120 source-test step; `docs/physical_qa_evidence.template.json` |
| Historical delivery wording | Documentation audit | PASS — README and test report point to the forward release gate and retain old candidates only as untested audit history | `README.md`, `docs/TEST_REPORT.md`, `docs/RELEASE_GATING.md` |
| Actual physical-device run | Android device or working emulator | OPEN — CI run 39102616120 again timed out before hosted-emulator boot; no device evidence was supplied or generated | A completed evidence JSON plus referenced install output/captures/logcat is required |

The handoff documents do not convert any prior headless/Xvfb/emulator-timeout result into a device pass. This batch is complete only as a reproducible test procedure; the real-device acceptance row remains deliberately open.

## M4 batch 15 — Highrise coordinate gate (local source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Graybox manifest shape | `python3 tools/validate_highrise_manifest.py` | PASS — M4 input manifest identifies `MP_RF_02`, reviewed card footprint, required zones/features, and waiting status | `data/highrise/MP_RF_02_graybox_manifest.json` |
| No guessed geometry | Highrise validator | PASS — waiting manifest has no coordinate records and `MP_RF_02` remains `COMING_SOON` / non-launchable | `tools/validate_highrise_manifest.py`; `data/maps/MP_RF_02.tres` |
| Project gate integration | `python3 tools/validate_project.py` | PASS — Highrise contract runs with regular source/resource validation | 2026-10-18 local terminal log |
| Graybox/nav/capture/Gate 2 | Real Godot scene and evidence pack | BLOCKED — authoritative B2 coordinates and the reference binary are not present in the checkout | `docs/HIGHRISE_GRAYBOX_INPUTS.md` |

This batch does not invent coordinates, launch a placeholder Highrise scene, or alter Desert ownership, waves, score, HP, controls, HUD, or current release policy. CI run [39103969150](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39103969150) also passed its source/native, import/export, normal-Boot gameplay, settings/menu, and genuine graphics-capture steps at `14a1bd6`; the Android emulator again timed out, release publication was skipped, and artifact upload was blocked by GitHub Actions storage quota. This remains source/runtime regression evidence, not Highrise graybox or physical-device evidence.

## M4 batch 16 — Highrise coordinate-packet contract (local source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Current waiting state | `python3 tools/validate_highrise_manifest.py` | PASS — schema 2 has no placement payload and retains the card lock | `data/highrise/MP_RF_02_graybox_manifest.json` |
| Contract regression suite | `python3 tools/test_validate_highrise_manifest.py` | PASS — 3 tests cover the committed waiting state, reject coordinates while waiting, and verify staged-source hash/feature-anchor enforcement using only temporary synthetic fixtures | `tools/test_validate_highrise_manifest.py` |
| Project-gate integration | `python3 tools/validate_project.py` | PASS — validator and its regression suite run before ordinary resource checks | `tools/validate_project.py` |
| CI source/runtime regression | GitHub Actions run 39109089804 at `a980410` | PASS — source/native, Godot import/export, normal-Boot/gameplay, settings/menu, and graphics-capture steps succeeded | [Run 39109089804](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39109089804) |
| Real B2 packet / graybox / Gate 2 | Authoritative appendix/reference plus Godot scene evidence | BLOCKED — both source artifacts remain absent; no scene was created | `docs/HIGHRISE_GRAYBOX_INPUTS.md` |

The staged schema deliberately keeps `MP_RF_02` locked. CI's Android emulator timed out again; candidate publication was skipped and evidence upload was blocked by GitHub Actions storage quota. It is an input-integrity check, not a substitute for authoritative map data, Godot navigation, renderer captures, director review, or device testing.

## M4 batch 17 — coordinate-free route topology (native source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Warning-clean C++ compile | `./scripts/run_native_tests.sh` | PASS — C++20, `-Wall -Wextra -Werror -pedantic` compiles the existing survival core and new topology core | `scripts/run_native_tests.sh` |
| Generic route behavior | `route_topology_test` | PASS — rejects malformed/duplicate topology, respects one-way/disabled links, finds a fallback route, and rejects unknown endpoints | `native/tests/route_topology_test.cpp` |
| Desert preservation | Existing `OperationCore` test in same command | PASS — 3 waves, 27 spawns, completion state unchanged | `native/tests/operation_core_test.cpp` |
| CI source/runtime regression | GitHub Actions run 39120796836 at `6f2e5a7` | PASS — source/native, import/export, normal-Boot/gameplay, settings/menu, and graphics-capture steps succeeded | [Run 39120796836](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39120796836) |
| Highrise endpoint/nav proof | Valid B2 packet plus Godot graybox/navigation evidence | BLOCKED — no Highrise endpoints are registered and no Godot nav scene exists | `docs/NAVIGATION_TOPOLOGY_CONTRACT.md` |

The native graph uses neutral test identifiers only. CI's Android emulator timed out again; candidate publication was skipped and evidence upload was blocked by GitHub Actions storage quota. It is not an `MP_RF_02` layout, does not replace Godot navigation, and cannot unlock the map.

## Batch 18 — Android emulator evidence hardening (workflow source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| KVM readiness contract | Workflow review + `python3 tools/validate_project.py` | PASS — explicit `/dev/kvm` access/read/write assertions run before the emulator action | `.github/workflows/android-apk.yml`; `tools/validate_project.py` |
| Accelerated emulator contract | Workflow review + project validator | PASS — emulator is required to use `-accel on` and has a bounded 480-second boot allowance | `.github/workflows/android-apk.yml` |
| Install/foreground evidence contract | Workflow review + project validator | PASS — saves `adb install -r` output, verifies package path, requires resumed activity, then scans logcat | `.github/workflows/android-apk.yml` |
| Revised hosted emulator run | GitHub Actions run 39121960890 at `7d6044c` | PASS for KVM/readiness and all non-device gates; BLOCKED for emulator launch — it timed out before boot even with KVM and 480 seconds | [Run 39121960890](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39121960890) |

This batch strengthens the definition of a later emulator pass and proves that KVM access alone does not resolve the hosted runner's boot failure. It does not bypass the named gate, publish an APK, or create physical-device evidence.

## Batch 19 — physical-evidence integrity contract (local source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Committed template boundary | `python3 tools/validate_physical_qa_evidence.py` | PASS — schema-1 template remains `TEMPLATE_NOT_EVIDENCE`, all D01–D12 rows are `NOT_RUN`, and no release classification can be implied | `docs/physical_qa_evidence.template.json` |
| Completed-record rules | `python3 tools/test_validate_physical_qa_evidence.py` | PASS — 3 tests reject a modified template and a false all-PASS classification; temporary synthetic fixtures prove valid PASS and honest BLOCKED record shapes | `tools/test_validate_physical_qa_evidence.py` |
| Project-gate integration | `python3 tools/validate_project.py` | PASS — template validator and regression suite run with the regular source checks | `tools/validate_project.py` |
| CI source/runtime regression | GitHub Actions run 39124905475 at `0220384` | PASS — source/native, import/export, normal-Boot/gameplay, settings/menu, graphics-capture, and KVM steps succeeded | [Run 39124905475](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39124905475) |
| Actual device evidence | Android device or successful emulator plus completed record | OPEN — no physical record or working hosted-emulator run exists | `docs/PHYSICAL_DEVICE_QA.md` |

The synthetic fixtures are test-only and are not Android evidence. The hosted emulator still timed out, candidate publication was skipped, and artifact upload was quota-blocked. This batch makes later evidence harder to misclassify; it does not convert the committed template, CI captures, or an emulator timeout into a device pass.

## M4 batch 20 — traversal-endpoint intake (local source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Waiting topology boundary | `python3 tools/validate_highrise_manifest.py` | PASS — schema-3 waiting manifest contains no coordinate, feature, or traversal-endpoint payload and keeps the card locked | `data/highrise/MP_RF_02_graybox_manifest.json` |
| Staged endpoint rules | `python3 tools/test_validate_highrise_manifest.py` | PASS — temporary synthetic packet must provide each bridge/rappel/lift/zipline with two different staged-zone endpoints, source reference, and directionality; a missing topology record is rejected | `tools/test_validate_highrise_manifest.py` |
| CI source/runtime regression | GitHub Actions run 39127188550 at `98a2623` | PASS — source/native, import/export, normal-Boot/gameplay, settings/menu, graphics-capture, and KVM steps succeeded | [Run 39127188550](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39127188550) |
| Navigation integration | Godot graybox/navigation adapter | BLOCKED — B2 appendix/reference and therefore authoritative endpoints are absent | `docs/HIGHRISE_GRAYBOX_INPUTS.md`; `docs/NAVIGATION_TOPOLOGY_CONTRACT.md` |

No endpoint association is recorded in project data. The hosted emulator still timed out, candidate publication was skipped, and artifact upload was quota-blocked. This is an intake contract only, not proof of a Highrise route, `NavigationLink3D`, bot behavior, or Gate 2.

## Batch 21 — documented Android-emulator baseline (workflow source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Persistent KVM configuration | Workflow review + `python3 tools/validate_project.py` | PASS — uses the emulator-runner documented udev rule and verifies `/dev/kvm` access before launch | `.github/workflows/android-apk.yml` |
| Distinct boot hypothesis | Workflow review + project validator | PASS — API-29/default x86_64 with explicit Linux hardware acceleration replaces the repeatedly timing-out API-30 ATD image | `.github/workflows/android-apk.yml` |
| Delivery/evidence guard | Workflow static validation | PASS — install output, package/foreground proof, crash scan, and named release dependency remain required | `.github/workflows/android-apk.yml`; `tools/validate_project.py` |
| New hosted baseline run | GitHub Actions run 39129496696 at `3446c62` | BLOCKED before emulator launch — source/export/capture gates passed, but the live udev preparation returned exit code 1 | [Run 39129496696](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39129496696) |

The image change is a bounded diagnostic probe. It does not weaken APK publication, classify an APK as tested, or replace physical-device QA.

## Batch 22 — resilient KVM fallback (workflow source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Documented-policy attempt | Workflow review + project validator | PASS — writes/reloads/triggers the documented KVM udev policy where the runner permits it | `.github/workflows/android-apk.yml` |
| Direct-node fallback | Workflow review + project validator | PASS — a reload/trigger failure logs its reason but the runner must still expose writable `/dev/kvm` after explicit permission before launch | `.github/workflows/android-apk.yml`; `tools/validate_project.py` |
| API-29 baseline preservation | Workflow review | READY — the distinct API-29/default x86_64 probe remains queued behind the KVM check | `.github/workflows/android-apk.yml` |
| Fallback hosted run | GitHub Actions run 39130099493 at `8dcad51` | PARTIAL PASS — KVM step passed and API-29 action ran, but its `/usr/bin/sh` inline script exited before install/launch evidence | [Run 39130099493](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39130099493) |

The fallback does not downgrade KVM verification: a missing or inaccessible `/dev/kvm` still fails the named Android gate, and candidate publication remains blocked.

## Batch 23 — POSIX emulator-script repair (workflow source gate)

| Check | Command / route | Result | Evidence |
| --- | --- | --- | --- |
| Shell portability contract | Workflow review + `python3 tools/validate_project.py` | PASS — action script uses POSIX `set -eu` and `[ ... ]`, not Bash-only options/conditionals | `.github/workflows/android-apk.yml`; `tools/validate_project.py` |
| Evidence path retained | Workflow source review | PASS — `adb install -r`, package lookup, resumed-activity check, and logcat scan remain unchanged after the shell repair | `.github/workflows/android-apk.yml` |
| Repaired API-29 run | GitHub Actions | PENDING — no emulator/device result is claimed before the POSIX-compatible probe executes | CI run for this batch is required |

The repair addresses an action-shell failure, not an APK or device pass. Candidate publication remains gated on a successful full emulator step.

## Outstanding test requirements
- Menu, touch, mouse, keyboard, gamepad and Android-back matrix after M2/M3.
- `MP_RF_02` bot navigation/floor/link/hazard tests before Gate 2 approval.
- Draw calls, visible triangles, texture memory, audio voice count and load timing at each Highrise quality tier.
- Physical Android install/launch/control test before a physical-device-final claim.
