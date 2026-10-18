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

**Batch 18 — Android emulator evidence hardening:** The release workflow now requires accessible KVM and `-accel on` before attempting the API 30 ATD emulator, then retains exact `adb install -r` output, confirms the package manager entry, and requires a resumed Operation Redline Android activity before accepting the crash-log scan. `tools/validate_project.py` statically protects that contract and candidate publication still requires the same successful `android_emulator` step. CI run [39121960890](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39121960890) passed all source/native, import/export, normal-Boot, settings/menu, graphics-capture, and new KVM-readiness steps at `7d6044c`; despite KVM success and a 480-second budget, the hosted emulator still timed out before boot. Candidate publication was skipped and evidence upload was quota-blocked. This is not a device pass or APK delivery. M4 remains coordinate-gated: `MP_RF_02` is non-launchable and the B2 appendix/reference is still required before graybox work.
