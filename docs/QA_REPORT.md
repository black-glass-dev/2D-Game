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

## Outstanding test requirements

- Menu, touch, mouse, keyboard, gamepad and Android-back matrix after M2/M3.
- `MP_RF_02` bot navigation/floor/link/hazard tests before Gate 2 approval.
- Draw calls, visible triangles, texture memory, audio voice count and load timing at each Highrise quality tier.
- Physical Android install/launch/control test before a physical-device-final claim.
