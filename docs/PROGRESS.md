# Operation Redline — Production Progress

Last updated: 2026-10-17 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, named actions, persistent conflict-aware keyboard/gamepad bindings, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → data-driven detail → threaded Loading → existing Desert hand-off. Settings persist through a reusable five-section surface, including live touch-layout preferences that preserve HUD-editor layouts and scoped keyboard/gamepad rebinding. Loading reports actual loader stages/progress/elapsed time; selected difficulty/mode now configures the Desert adapter while Normal/Survival remains exact. The Boot menu's original static non-LOW and no-texture LOW fallback both have normal-Boot renderer evidence. `MP_RF_02` remains an inspectable but locked future card. |
| M3 — Deliverable A QA | In progress | Pause lifecycle, results, SFX/UI buses, live accessibility/input/layout/rebinding adapters, tactical captions, and Back-route normal-Boot regression coverage are validated. The original Music-bus loop and its source/mix/memory review are implemented locally; its normal-Boot CI result, manual device input/audio matrix, and physical-device evidence remain. |
| M4 — Highrise graybox and systems | Not started | Gate 2 requires director review after navigation/capture evidence. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**M3 Batch 12 — original Music-bus loop awaiting normal-Boot evidence:** `AudioService` now owns one source-controlled, non-lyrical `outpost_watch.wav` loop. It is mono PCM (22,050 Hz, 16-bit, 16 seconds, 705,644 bytes), forwards loops at -16 dB before the existing Music slider, stops at explicit Music volume zero, and resumes when Music is enabled. `docs/AUDIO_ASSET_REVIEW.md` records the original-source provenance, reproducible generator, no-sample policy, memory boundary, relative mix, and remaining human-listening limit. Local generator, waveform, source/resource/native checks pass; the extended normal-Boot `AUDIO_FLOW_PASS` and real device listening result are not yet available, so no audible or physical-device claim is made.
