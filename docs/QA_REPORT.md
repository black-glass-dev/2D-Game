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
| Resource links and original texture dimensions | `python3 tools/validate_project.py` | PASS — 47 `res://` links and 4 128×128 textures | M1 Batch 2 terminal log |
| Native survival core | `./scripts/run_native_tests.sh` | PASS — 3 waves, 27 spawns, completion | M1 Batch 2 terminal log |
| Asset manifest syntax and font hashes | `python3 -m json.tool assets_manifest.json`; `sha256sum` | PASS — manifest parses; Regular/SemiBold match the recorded hashes | M1 Batch 2 terminal log |
| Godot import, Android export, and headless Boot route | GitHub Actions run 38684364680 | PASS | `https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38684364680` — import/export/headless/capture steps succeeded on `2fadc30` |
| Android emulator install/launch | GitHub Actions run 38684364680 | BLOCKED — emulator boot timeout | APK candidate and build evidence uploaded, but the hosted emulator did not boot before timeout; this is not a device-pass result |

## Outstanding test requirements

- Real Godot headless launch after every code-bearing batch.
- Menu, touch, mouse, keyboard, gamepad and Android-back matrix after M2/M3.
- `MP_RF_02` bot navigation/floor/link/hazard tests before Gate 2 approval.
- Draw calls, visible triangles, texture memory, audio voice count and load timing at each Highrise quality tier.
- Physical Android install/launch/control test before a physical-device-final claim.
