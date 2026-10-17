# Operation Redline — Production Progress

Last updated: 2026-10-17 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, named actions, persistent conflict-aware keyboard/gamepad bindings, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → data-driven detail → threaded Loading → existing Desert hand-off. Settings persist through a reusable five-section surface, including live touch-layout preferences that preserve HUD-editor layouts and scoped keyboard/gamepad rebinding. Loading reports actual loader stages/progress/elapsed time; selected difficulty/mode now configures the Desert adapter while Normal/Survival remains exact. The Boot menu now selects an original static outpost image for non-LOW or a no-texture procedural outpost for explicit LOW; the new normal-Boot renderer-evidence run is the next gate. `MP_RF_02` remains an inspectable but locked future card. |
| M3 — Deliverable A QA | In progress | Pause lifecycle, results, SFX/UI buses, live accessibility/input/layout/rebinding adapters, tactical captions, and Back-route normal-Boot regression coverage are validated. Manual device input/audio matrix and physical-device evidence remain. |
| M4 — Highrise graybox and systems | Not started | Gate 2 requires director review after navigation/capture evidence. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**M2 Batch 11 — menu backdrop renderer evidence recorded:** The Boot shell uses `assets/ui/menu_desert_outpost.png` for `AUTO`, `MEDIUM`, `HIGH`, and `ULTRA`; explicit `LOW` selects only flat procedural `ColorRect` desert/outpost geometry. Neither route starts `Main`, a 3D scene, AI, combat, or menu input simulation. CI run [39030720943](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39030720943) passed source/native checks, Godot import/debug export/signature, every normal-Boot contract including `MENU_BACKGROUND_PASS`, pause/Bengali rendering, the real Xvfb high/LOW menu capture, and full before/after graphics capture. It committed `screenshots/menu/menu_background_high.png` (490475 bytes, SHA-256 `dc30ba4a37d1a21d8b2affcfd1bb154ecd3632fd8e5147be0b37b11fccbf05c1`) and `menu_background_low.png` (32726 bytes, SHA-256 `e0926038c12720271849cdc9b47d6191e724158a312052994956297097db0544`) at 1280×720 in `630e9c2`. The hosted emulator still timed out and Actions artifact storage remains full; this is renderer evidence, not a physical-device test or APK delivery.
