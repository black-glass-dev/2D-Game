# Operation Redline — Production Progress

Last updated: 2026-10-15 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, additive input actions, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. Full control rebinding remains. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → data-driven detail → threaded Loading → existing Desert hand-off. Settings persist through a reusable five-section surface. `MP_RF_02` is an inspectable but locked future card; session difficulty/mode selection is stored without changing current Desert balance. Live in-game preview, modifier adapter, loading telemetry, and final background fallback remain. |
| M3 — Deliverable A QA | Not started | Desert regression, pause/end flow, evidence and Android candidate. |
| M4 — Highrise graybox and systems | Not started | Gate 2 requires director review after navigation/capture evidence. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**M2 Batch 3 validated:** Map Select reads both the playable Desert resource and locked Highrise metadata, offers a localized tactical detail panel, and stores pre-deployment difficulty/mode selection without modifying Desert combat balance. CI run 38747901596 passed source checks, Godot import, Android export, boot/settings/map-select headless checks, and renderer capture. Hosted emulator boot remains the physical-device evidence blocker.
