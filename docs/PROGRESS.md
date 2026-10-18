# Operation Redline — Production Progress

Last updated: 2026-10-18 (Asia/Dhaka)

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| M0 — Registration and safety baseline | Complete | Recon, plan, source-control audit, live-document scaffold, and repeat validation are recorded. |
| M1 — Foundation services | In progress | Batches 1–2 provide autoload contracts, versioned settings/save data, `MapData`, `MP_DS_01`, named actions, persistent conflict-aware keyboard/gamepad bindings, bilingual CSV localization, an OFL Bengali font, shared theme, and source SVG icons. |
| M2 — Deliverable A flow | In progress | `Boot.tscn` implements Splash → Main Menu → data-driven detail → threaded Loading → existing Desert hand-off. Settings persist through a reusable five-section surface, including live touch-layout preferences that preserve HUD-editor layouts and scoped keyboard/gamepad rebinding. Loading reports actual loader stages/progress/elapsed time; selected difficulty/mode now configures the Desert adapter while Normal/Survival remains exact. The Boot menu's original static non-LOW and no-texture LOW fallback both have normal-Boot renderer evidence. `MP_RF_02` remains an inspectable but locked future card. |
| M3 — Deliverable A QA | In progress | Pause lifecycle, results, SFX/UI buses, live accessibility/input/layout/rebinding adapters, tactical captions, Back-route regression coverage, original Music-bus loop contract, release-truth gate, and an evidence-bound physical-device matrix are implemented. Actual device input/audio evidence remains. |
| M4 — Highrise graybox and systems | In progress — input gate | `MP_RF_02` remains locked while a validated manifest records the known topology and blocks guessed geometry. Authoritative B2 coordinates/reference, graybox/nav/capture evidence, and Gate 2 review remain. |
| M5 — Highrise art and optimization | Not started | CC0/procedural assets, audio, lighting, performance budgets. |
| M6 — QA and release | Not started | Two-map acceptance matrix and signed release candidate. |

## Current batch

**Batch 22 — resilient KVM baseline probe:** CI run [39129496696](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39129496696) passed source/native, import/export, normal-Boot, settings/menu, and graphics-capture gates at `3446c62` but failed the live KVM udev preparation before the API-29 emulator could start. The workflow now preserves the documented udev attempt while falling back to the earlier verified direct `/dev/kvm` permission check when reload/trigger is unavailable. The API-29/default x86_64 hypothesis, explicit hardware acceleration, install/package/foreground/crash evidence, and candidate-publication guard remain intact. This is not a pass or APK delivery—the next CI run must establish the fallback probe outcome. M4 remains coordinate-gated: `MP_RF_02` is non-launchable and the B2 appendix/reference is still required before graybox work.
