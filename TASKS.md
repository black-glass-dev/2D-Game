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
- [x] Connect the shared settings surface to a state-authoritative pause overlay with renderer-backed Bengali evidence.
- [ ] Add live in-game visual/control-layout previews and complete conflict-aware rebinding.
- [x] Add map detail, difficulty/mode session selection, and a locked `MP_RF_02` future-map card without exposing a launch route.
- [ ] Add loading telemetry, make difficulty/mode affect the Desert compatibility adapter, and add the visual menu background fallback.

## M3 — Deliverable A regression QA

- [x] Add a state-authoritative pause/back/focus-loss lifecycle with shared settings and renderer-backed Bengali UI evidence.
- [x] Persist Desert operation best score/furthest wave; show result summary and Map Select record without changing the wave director balance.
- [x] Route current combat and menu/settings feedback through SFX/UI buses; implement saved-volume-safe focus mute/restore and headless regression coverage.
- [x] Make subtitles, reduced-motion, colorblind HUD, damage-number, haptic, and gamepad-deadzone preferences operational in Desert; add normal-Boot input/accessibility coverage.
- [x] Add normal-Boot Android Back, Escape, controller-B, and paused-settings return/resume route coverage.
- [ ] Validate the complete touch, mouse, keyboard, gamepad, Android Back, focus-mute/restore, quality-tier, language, and audible mix matrix on real devices where available.
- [ ] Add licensed/original background music only after a separate provenance, mix, and mobile-memory review.

## Guardrails

- [ ] Preserve the existing playable Desert Outpost at every commit.
- [ ] Keep Android package identifier and persistent debug signing stream unchanged.
- [ ] Do not use commercial-game assets, branding, maps, names, or ripped content.
- [ ] Do not mark a physical-device test as passed without evidence.
