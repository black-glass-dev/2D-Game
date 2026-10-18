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

**Batch 26 — workspace-absolute emulator probe:** CI run [39132269643](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39132269643) at `25d344e` passed source/native, import/export, normal-Boot, settings/menu, graphics-capture, and KVM, but the API-29 action still failed before installation/foreground evidence. The single-file relative probe did not leave its trace in the checkout, so the action now calls the file through `$GITHUB_WORKSPACE` and the file uses workspace-absolute APK/log paths; the failure marker is run-specific so it cannot silently deduplicate. No installation, foreground, device success, or APK delivery is claimed until one run completes that evidence chain. M4 remains coordinate-gated: `MP_RF_02` is non-launchable and the B2 appendix/reference is still required before graybox work.
