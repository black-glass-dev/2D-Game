# Operation Redline — Task Board

## In progress

- [x] M0.1 Register the verified source-control baseline and living production documents.
- [x] M0.2 Repeat static/resource/native validation against the registered baseline.
- [x] M0.3 Record the first QA baseline and close M0.

## Next: M1 foundation

- [x] Add additive service/autoload architecture without changing Desert gameplay ownership.
- [x] Introduce schema-versioned settings and save migration contracts.
- [x] Add the initial Bengali/English localization CSV catalog and a compatible OFL font family with provenance.
- [x] Create shared Redline UI theme and original SVG icon source set.
- [x] Introduce `MapData`, `MapRegistry`, and an `MP_DS_01` Desert compatibility resource.
- [x] Add named InputMap actions while preserving legacy input; conflict-aware rebind UI remains next.

## M2 started — Deliverable A flow

- [x] Add an independently runnable Boot → Splash → Main Menu shell.
- [x] Add a data-driven Desert map card and threaded `SceneLoader` hand-off.
- [x] Add a touch/keyboard/gamepad navigation baseline plus Android Back route in the shell.
- [x] Add five categorized settings sections, persistence, reset confirmation, immediate audio/FPS application, and legacy Desert compatibility write-through.
- [ ] Connect the shared settings surface to pause, add live in-game visual/control-layout previews, and complete conflict-aware rebinding.
- [ ] Add map difficulty/mode selection, locked future-map card, loading telemetry, and visual menu background fallback.

## Guardrails

- [ ] Preserve the existing playable Desert Outpost at every commit.
- [ ] Keep Android package identifier and persistent debug signing stream unchanged.
- [ ] Do not use commercial-game assets, branding, maps, names, or ripped content.
- [ ] Do not mark a physical-device test as passed without evidence.
