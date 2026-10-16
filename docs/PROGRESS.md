# Operation Redline — Production Progress

Last updated: 2026-10-16 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, named actions, persistent conflict-aware keyboard/gamepad bindings, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → data-driven detail → threaded Loading → existing Desert hand-off. Settings persist through a reusable five-section surface, including live touch-layout preferences that preserve HUD-editor layouts and scoped keyboard/gamepad rebinding. `MP_RF_02` is an inspectable but locked future card; session difficulty/mode selection is stored without changing current Desert balance. Modifier adapter, loading telemetry, and final background fallback remain. |
| M3 — Deliverable A QA | In progress | Pause lifecycle, results, SFX/UI buses, live accessibility/input/layout/rebinding adapters, tactical captions, and Back-route normal-Boot regression coverage are validated. Manual device input/audio matrix and physical-device evidence remain. |
| M4 — Highrise graybox and systems | Not started | Gate 2 requires director review after navigation/capture evidence. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**M3 Batch 8 validated:** Controls now include keyboard rows for every named gameplay action and gamepad-button rows for fire, aim, jump, crouch, swap, reload, and pause. Capture rejects same-surface conflicts by naming the conflicting action; Escape/controller B cancel capture; defaults restore through a separate `user://input_bindings.cfg` contract while mouse, touch, analog-stick, menu, and Back bindings remain protected. CI run [38914993211](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/38914993211) passed source/native checks, import, debug APK export/signature, all normal-Boot gates including `REBIND_FLOW_PASS`, pause/Bengali capture, and full real renderer capture. The hosted emulator again timed out before boot, and Actions artifact storage remains full; this is not physical-device evidence or APK delivery.
