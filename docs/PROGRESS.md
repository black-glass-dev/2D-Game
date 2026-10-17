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

**M2 Batch 11 — menu backdrop implementation awaiting renderer evidence:** The Boot shell now uses `assets/ui/menu_desert_outpost.png` for `AUTO`, `MEDIUM`, `HIGH`, and `ULTRA`; explicit `LOW` selects only flat procedural `ColorRect` desert/outpost geometry. Neither route starts `Main`, a 3D scene, AI, combat, or menu input simulation. `--verify-menu-background-flow` proves the LOW/non-LOW selection contract and `--capture-menu-backgrounds` writes named high/LOW frames only from a normal Xvfb Boot run. Local source/native/resource/asset-provenance checks passed on 2026-10-17; the first CI renderer output and its commit are not yet available, so no visual-verification or device claim is made.
