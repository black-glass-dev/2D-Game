# Operation Redline — Production Progress

Last updated: 2026-10-15 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, additive input actions, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. Full control rebinding remains. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → Map Select → threaded Loading → existing Desert hand-off. Full settings, mode/difficulty controls, future-map card, and final background fallback remain. |
| M3 — Deliverable A QA | Not started | Desert regression, pause/end flow, evidence and Android candidate. |
| M4 — Highrise graybox and systems | Not started | Gate 2 requires director review after navigation/capture evidence. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**M1 Batch 2 / M2 entry-flow hand-off:** the default boot scene is now a lightweight UI shell. It shows splash/menu/map selection before using `SceneLoader` to load the unchanged `Main.tscn` Desert runtime. Godot import, Android export, and default Boot launch passed in CI run 38684364680. The first direct integration test (run 38685720708) correctly exposed a MapRegistry constant, Translation-resource, and `.tres` syntax defect; all three are corrected. A normal-project `--verify-boot-flow` run now exercises the full Boot → SceneLoader → Main hand-off and is re-queued. Hosted emulator boot remains an evidence blocker.
