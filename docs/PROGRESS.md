# Operation Redline — Production Progress

Last updated: 2026-10-15 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, additive input actions, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. Full control rebinding remains. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → Map Select → threaded Loading → existing Desert hand-off. A reusable five-section Settings surface persists preferences and mirrors legacy Desert settings. Mode/difficulty controls, future-map card, live in-game preview, and final background fallback remain. |
| M3 — Deliverable A QA | Not started | Desert regression, pause/end flow, evidence and Android candidate. |
| M4 — Highrise graybox and systems | Not started | Gate 2 requires director review after navigation/capture evidence. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**M2 Batch 2 in progress:** `RedlineSettingsMenu` provides graphics, audio, controls, accessibility, and other sections with automatic persistence and reset confirmation. Audio volumes apply immediately; current Desert consumers receive explicit quality tier, look sensitivity, aim-assist, fire-mode, and screen-effects compatibility values on the next map hand-off. Real Godot export/headless verification is required after this settings batch. Hosted emulator boot remains the physical-device evidence blocker.
