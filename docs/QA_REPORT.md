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

## Outstanding test requirements

- Menu, touch, mouse, keyboard, gamepad and Android-back matrix after M2/M3.
- `MP_RF_02` bot navigation/floor/link/hazard tests before Gate 2 approval.
- Draw calls, visible triangles, texture memory, audio voice count and load timing at each Highrise quality tier.
- Physical Android install/launch/control test before a physical-device-final claim.
