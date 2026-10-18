# Operation Redline — Production Progress

Last updated: 2026-10-17 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, named actions, persistent conflict-aware keyboard/gamepad bindings, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → data-driven detail → threaded Loading → existing Desert hand-off. Settings persist through a reusable five-section surface, including live touch-layout preferences that preserve HUD-editor layouts and scoped keyboard/gamepad rebinding. Loading reports actual loader stages/progress/elapsed time; selected difficulty/mode now configures the Desert adapter while Normal/Survival remains exact. The Boot menu's original static non-LOW and no-texture LOW fallback both have normal-Boot renderer evidence. `MP_RF_02` remains an inspectable but locked future card. |
| M3 — Deliverable A QA | In progress | Pause lifecycle, results, SFX/UI buses, live accessibility/input/layout/rebinding adapters, tactical captions, Back-route regression coverage, original Music-bus loop contract, release-truth gate, and an evidence-bound physical-device matrix are implemented. Actual device input/audio evidence remains. |
| M4 — Highrise graybox and systems | Not started | Gate 2 requires director review after navigation/capture evidence. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**M3 Batch 14 — physical QA handoff prepared, not executed:** `docs/PHYSICAL_DEVICE_QA.md` now defines the full touch/mouse/keyboard/gamepad/Back/focus/settings/language/quality/audio/survival device matrix, and `physical_qa_evidence.template.json` requires exact APK/source/device identity, `adb install -r` output, result states, and capture/log paths. `TEST_REPORT.md` and `README.md` were corrected so historical pre-releases are not presented as current tested/downloadable deliveries. CI run [39102616120](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39102616120) passed the source validator and all non-device gates, while the hosted emulator again timed out. No physical device or working emulator has executed this matrix; the template itself is explicitly not evidence. The forward release gate and the physical matrix remain the required path to any later delivery claim.
