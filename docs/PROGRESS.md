# Operation Redline — Production Progress

Last updated: 2026-10-17 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, named actions, persistent conflict-aware keyboard/gamepad bindings, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → data-driven detail → threaded Loading → existing Desert hand-off. Settings persist through a reusable five-section surface, including live touch-layout preferences that preserve HUD-editor layouts and scoped keyboard/gamepad rebinding. Loading reports actual loader stages/progress/elapsed time; selected difficulty/mode now configures the Desert adapter while Normal/Survival remains exact. `MP_RF_02` is an inspectable but locked future card; the final background fallback remains. |
| M3 — Deliverable A QA | In progress | Pause lifecycle, results, SFX/UI buses, live accessibility/input/layout/rebinding adapters, tactical captions, and Back-route normal-Boot regression coverage are validated. Manual device input/audio matrix and physical-device evidence remain. |
| M4 — Highrise graybox and systems | Not started | Gate 2 requires director review after navigation/capture evidence. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**M2 Session Adapter validated:** Map-select difficulty and mode now configure the live Desert wave director. Normal/Survival retains the exact 6/9/12 count profile, 0.83/0.71/0.59-second spawn cadence, score/HP model, and third-wave completion; Easy/Hard/Nightmare change only cadence, while Endless repeats 6/9/12 and exposes an infinite HUD wave limit. CI run [39015842921](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39015842921) passed source/native checks, import, debug APK export/signature, all normal-Boot gates including `SESSION_ADAPTER_PASS`, pause/Bengali capture, and full real renderer capture. The hosted emulator again timed out before boot, and Actions artifact storage remains full; this is not physical-device evidence or APK delivery.
