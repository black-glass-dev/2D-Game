# Operation Redline — Production Progress

Last updated: 2026-10-17 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, named actions, persistent conflict-aware keyboard/gamepad bindings, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → data-driven detail → threaded Loading → existing Desert hand-off. Settings persist through a reusable five-section surface, including live touch-layout preferences that preserve HUD-editor layouts and scoped keyboard/gamepad rebinding. Loading reports actual loader stages/progress/elapsed time; selected difficulty/mode now configures the Desert adapter while Normal/Survival remains exact. The Boot menu's original static non-LOW and no-texture LOW fallback both have normal-Boot renderer evidence. `MP_RF_02` remains an inspectable but locked future card. |
| M3 — Deliverable A QA | In progress | Pause lifecycle, results, SFX/UI buses, live accessibility/input/layout/rebinding adapters, tactical captions, Back-route regression coverage, original Music-bus loop contract, and a forward-only Android APK release-truth gate are implemented. Manual device input/audio matrix and physical-device evidence remain. |
| M4 — Highrise graybox and systems | Not started | Gate 2 requires director review after navigation/capture evidence. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**M3 Batch 13 — release-truth gate verified:** The Android workflow names its install/launch step `android_emulator` and requires that step, APK export, and normal-Boot gameplay checks to succeed before `gh release create` can publish a player-downloadable candidate. CI run [39034299154](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39034299154) passed source/native, import/export/signature, normal-Boot, and renderer gates; its hosted emulator timed out, after which `Publish a device-validated debug APK candidate` was correctly skipped. No `apk-candidate-88` release was created; package ID and persistent debug-signing compatibility remain unchanged. `docs/RELEASE_GATING.md` records the policy and the non-tested status of historical pre-releases. Artifact quota and physical-device evidence remain separate blockers.
