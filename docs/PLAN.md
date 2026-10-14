# Operation Redline — Production Plan (M0–M6)

**তারিখ:** 2026-10-14 (Asia/Dhaka)

**স্ট্যাটাস:** Execution authorized by the director on 2026-10-14; M0 is complete and M1 is next.
**নিয়ম:** Deliverable A আগে সম্পূর্ণ হবে; তারপর Gate 2 অনুমোদন নিয়ে Deliverable B art pass শুরু হবে। প্রতিটি batch শেষে boot/test evidence, changelog, progress এবং QA entry লেখা হবে।

## Delivery order

1. **Deliverable A:** Boot → Splash → Main Menu → Map Select → async Loading → Gameplay, full settings/persistence/localization/pause/end flow.
2. **Deliverable B:** `MP_RF_02` Rooftop Highrise — graybox থেকে nav/system/art/optimization/QA।
3. **Non-regression contract:** `MP_DS_01` Desert Outpost প্রতিটি commit-এর পরে selectable এবং playable থাকবে; existing HUD/touch combat will be preserved while being packaged behind the new services.

## Milestones

| Milestone | Scope | Planned batches | Exit criteria |
| --- | --- | ---: | --- |
| **M0 — Registration & safety baseline** | Repository registration, file hashes, documentation scaffold, source inventory, project guardrails | 2 | All existing source is registered without generated outputs; untouched Desert boots/headless launches; `PROGRESS`, `TASKS`, `CHANGELOG`, `DESIGN_DECISIONS`, `RISKS`, `QA_REPORT`, `ASSET_IMPORT_LOG`, and asset manifest scaffolds exist; baseline checks recorded. |
| **M1 — Foundation services** | `GameManager`, `SceneLoader`, `SettingsService`, `SaveService`, `AudioService`, `MapRegistry`, `InputService`; schema-version migration; English/Bengali localization CSV and font pipeline; shared theme/icons | 4 | Autoload state transitions are traceable; `user://settings.cfg` and `user://save.json` migrate current settings/layout safely; device Auto locale resolves to Bengali/English; UI strings have no gameplay hard-code dependency; Desert still launches through compatibility adapter. |
| **M2 — Deliverable A flow** | Splash, 3D/fallback menu background, Main Menu, full settings, data-driven Map Select, locked cards, real threaded Loading screen | 5 | Boot shows title/settings within 3 seconds; keyboard/mouse/gamepad/touch navigation works; all settings live-apply and persist; `MP_DS_01` card is playable; registry discovers `.tres` map entries; missing menu asset has text/static fallback. |
| **M3 — Deliverable A completion & regression QA** | Pause/back behaviour, focus-loss pause/mute, Game Over/Mission Complete, score persistence, menu audio, loading telemetry, map thumbnail renderer, Android UX pass | 4 | A1–A9 acceptance criteria pass for Desert; every back route is deterministic; 44 px minimum menu targets; screenshot/evidence set and test report exist; Android debug candidate is exported only after all gates pass. |
| **M4 — Deliverable B graybox & systems** | `MP_RF_02` scene/data, 3-level graybox, navigation, spawn profile, cover/link graph, roof/office/lobby mechanics in functional placeholder form | 5 | Exact B2 footprint/heights/gaps/bridges/skylights exist; 4 corner captures + top-down comparison produced; floor bot-walk tests pass; all named spawn groups and ≥12 cover hotspots resolve; Desert’s `6/9/12` behaviour remains unchanged. **Gate 2: director review required before art pass.** |
| **M5 — Highrise art, audio & optimization** | CC0/procedural asset intake, flat-shaded industrial art, glass/skylight, zipline, rappel/elevator links, helipad objective, lighting/audio, LOD/occlusion/instancing | 6 | Legal asset ledger + hashes complete; quality tiers meet budget design; W1–final sequence works; all required systems have functional fallback; profiling captures show Android target budget or specific documented blocker. |
| **M6 — QA, release & handoff** | Automated tests, gameplay regression matrix, loading timing, APK signing/export, physical-device checklist, release notes | 3 | Both map cards launch from menu; all A and B Definition-of-Done items have evidence; source/native/headless/renderer/Android export pass; APK builds from the protected direct-update signing stream; remaining physical-device findings are explicitly recorded rather than hidden. |

## Batch sequencing detail

### M0 — Registration & safety baseline

1. Record current file inventory/sha256 and make the existing full project a reviewed baseline commit without bundling `.godot`, `node_modules`, APKs or downloaded tool caches.
2. Add required living-document templates and a test command matrix; write the initial risk/decision entries. No gameplay restructuring in M0.

### M1 — Foundation services

1. Add locale/font resources and `ui/theme/redline_theme.tres`; build reusable SVG icon source set.
2. Introduce schema-versioned settings/save services and migrate `operation_redline_settings.cfg` plus current HUD layout without data loss.
3. Add state manager/transition overlay and scene-loader contract while retaining `Main.tscn` as an independently runnable legacy gameplay entry.
4. Add `MapData`, MapRegistry scan, `MP_DS_01` data resource and Desert compatibility adapter; establish input abstraction/rebinding persistence without deleting legacy input paths.

### M2 — Deliverable A flow

1. Implement splash and resilient main-menu shell with procedural/desert menu rig and static fallback.
2. Implement full settings sections, runtime preview hooks, pause-menu entry and restore/reset confirmation.
3. Implement map cards/detail panel/difficulty-mode state and locked future map cards; create `MP_RF_02` metadata card before its scene is playable.
4. Implement genuine threaded load route and telemetry, then map-thumbnail capture utility plus `ScreenshotAnchor` contract.
5. Validate menu touch, keyboard, gamepad and Android back paths before committing M2.

### M3 — Deliverable A completion & regression QA

1. Connect pause/focus-loss/run-end flow to current waves, score, accuracy and retry logic without duplicate director ownership.
2. Add menu/UI audio buses, focus mute/restore and accessible feedback/fallback paths.
3. Execute Desert regression matrix at each quality tier, language and control type; inspect real captures.
4. Export candidate APK and record evidence. If hosted emulator still cannot boot, document it; do not claim a physical device pass.

### M4 — Deliverable B graybox & systems

1. Create the Highrise root scene, coordinate grid, grey material and roof/office/lobby blockout against the authoritative B2 dimensions.
2. Add `NavigationRegion3D`, floor-aware links, cover markers and deterministic bot-walk harnesses; do not advance until nav errors are fixed.
3. Add safe functional versions of breakable glass, skylight danger, fall damage, zipline, rappels, lift shaft link, supply nodes and breach gates.
4. Make `SpawnProfile` map-driven; implement specified W1–final schedule and helipad 90-second hold logic.
5. Produce Gate 2 capture pack: roof-corner views, top-down reference comparison, office/lobby walkthrough and nav report. Stop for director approval before art.

### M5 — Highrise art, audio & optimization

1. Run `tools/fetch_assets.py` + manifest workflow; use only documented CC0/permissive sources and generate procedural fallbacks on failure.
2. Replace graybox systematically by roof/office/lobby zones, keeping collision/nav separate from cosmetic models.
3. Apply day lighting, procedural/CC0 sky fallback, floor ambience, SFX and quality-tier visibility rules.
4. Add `MultiMesh`/instancing/LOD and occlusion layout; capture draw-call/triangle/material/audio metrics.
5. Complete final-wave helipad/extraction feedback and all accessibility/localization strings.
6. Conduct visual/combat/performance QA on both maps.

### M6 — QA, release & handoff

1. Expand static/native tests for map profiles, settings migrations and state transitions; run headless scene tests and real renderer captures.
2. Perform manual desktop/mobile input matrix and an Android physical-device playtest when a device is available.
3. Export signed direct-update APK, verify package/signature, publish release evidence, and update all live documents.

## Required decisions and default recommendations

| ID | Decision | Recommended default | Why / alternative |
| --- | --- | --- | --- |
| D-01 | Existing Desert ID/name | `MP_DS_01`, **Desert Outpost / Desert Outpost** | User authorized this fallback if a final name is not supplied. Rename is metadata-only later. |
| D-02 | Language selection | `Auto` by device locale; Bangla for `bn*`, English otherwise; manual override persists | Meets language rule with a safe fallback if a locale/font is unavailable. |
| D-03 | Menu background on low-power devices | Static generated/blurred Desert thumbnail with subtle pan | Avoids activating AI, HUD and full world simulation behind menu. Alternative is full 3D rail camera on every device, rejected for battery/performance risk. |
| D-04 | `MapRegistry` discovery | Scan the future `data/maps/` resource folder for `.tres`, validate each `MapData`, skip invalid entries with user-visible fallback | New map remains data-only. An explicit code array is simpler but violates the one-minute map-add requirement. |
| D-05 | Desert migration | Wrap current procedural `WorldBuilder` in `MP_DS_01` adapter before extracting systems | Rewriting it into a new map scene at once risks breaking the currently playable map. |
| D-06 | Highrise reference availability | Use B2 coordinate specification as authoritative if binary reference is still unavailable | Exact numeric coordinates are sufficient for graybox; log every visual-only inference. |
| D-07 | Highrise gameplay state | Build safe functional fallback behaviours before polish | Navigation/link/traversal correctness comes before artwork; no system will be blocked by missing third-party art. |
| D-08 | Input rebinding | Persist a limited, conflict-aware action table through `InputService`, preserve direct legacy fallback during migration | Full raw-event editor is possible later; this is safer for Android and current keyboard code. |
| D-09 | Build release status | Debug candidates only until physical Android launch/control test is evidenced | The existing hosted emulator timeout must not be misrepresented as a device pass. |

## Definition of Done — per batch

A batch is only marked done when all applicable items are true:

- [ ] Scope and design decision are recorded before implementation.
- [ ] Desert Outpost still boots/plays, unless the batch is explicitly isolated to a new non-default scene.
- [ ] Static GDScript/resource/native tests pass, plus a real Godot/headless launch where the environment permits it.
- [ ] No missing `res://` references, parse warnings, untracked generated cache, or secret/signing material is added.
- [ ] New player-facing text has Bangla and English localization keys.
- [ ] New settings/save data have schema version, migration and default fallback.
- [ ] Quality/performance cost and fallback are defined.
- [ ] Legal source/licence/hash is recorded for each downloaded asset; failed acquisition is recorded with a procedural fallback.
- [ ] Screenshot/log/file-path evidence is linked in `QA_REPORT.md`.
- [ ] `PROGRESS.md`, `TASKS.md`, `CHANGELOG.md`, `RISKS.md`, and `DESIGN_DECISIONS.md` are updated before the batch report.

## Approval gates

- **Start gate:** this plan intentionally stops here. Work begins only after the director replies **“চালাও”**.
- **Gate 2:** after `MP_RF_02` graybox + nav captures; art pass starts only after director approval.
- **Release gate:** no final physical-device-tested APK claim without recorded device launch and control test evidence.
